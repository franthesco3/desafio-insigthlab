//! Timeline de uma sala: mensagens, paginação e envio.
//!
//! O envio usa o *local echo* do `Timeline`: a mensagem aparece na hora como
//! "enviando" e o próprio stream da timeline passa a "enviada" ou "falhou".

use futures_util::{pin_mut, StreamExt};
use matrix_sdk::ruma::{
    api::client::receipt::create_receipt::v3::ReceiptType,
    events::room::message::{MessageType, RoomMessageEventContent},
};
use matrix_sdk_ui::timeline::{
    EventSendState, EventTimelineItem, MsgLikeKind, TimelineDetails, TimelineItem,
    TimelineItemContent,
};

use crate::{
    api::error::{MatrixError, MatrixErrorKind},
    frb_generated::StreamSink,
    sync_runtime,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MessageKindDto {
    /// `m.text`, `m.notice` ou `m.emote`: `body` traz o texto.
    Text,
    /// Mensagem apagada (redacted).
    Redacted,
    /// Criptografada sem chave disponível neste dispositivo.
    Undecryptable,
    /// Tipo ainda não suportado: `event_type` traz o tipo (ex.: `m.image`).
    Unsupported,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SendStateDto {
    Sending,
    Sent,
    Failed,
}

pub struct MessageDto {
    /// Event ID ou, enquanto for local echo, o ID da transação.
    pub id: String,
    pub sender_id: String,
    pub sender_name: String,
    pub kind: MessageKindDto,
    pub body: Option<String>,
    pub event_type: Option<String>,
    /// Milissegundos desde a época Unix.
    pub timestamp_ms: i64,
    pub is_own: bool,
    pub send_state: SendStateDto,
}

/// Emite as mensagens da sala, da mais antiga para a mais recente, a cada
/// mudança. Itens que não são mensagens (entradas na sala, mudanças de nome,
/// divisores de data) são omitidos.
pub async fn watch_timeline(room_id: String, sink: StreamSink<Vec<MessageDto>>) {
    let timeline = match sync_runtime::timeline(&room_id).await {
        Ok(timeline) => timeline,
        Err(error) => {
            let _ = sink.add_error(error.into_stream_error());
            return;
        }
    };

    // Carrega os perfis dos membros para exibir nomes em vez de IDs.
    let members = tokio::spawn({
        let timeline = timeline.clone();
        async move { timeline.fetch_members().await }
    });
    sync_runtime::track(members.abort_handle()).await;

    let task = tokio::spawn(async move {
        let (mut items, diffs) = timeline.subscribe().await;
        pin_mut!(diffs);

        loop {
            if sink
                .add(items.iter().filter_map(to_message).collect())
                .is_err()
            {
                break; // O Dart cancelou a assinatura.
            }
            let Some(batch) = diffs.next().await else {
                break;
            };
            for diff in batch {
                diff.apply(&mut items);
            }
        }
    });
    sync_runtime::track(task.abort_handle()).await;
}

/// Carrega até `count` eventos anteriores. Retorna `true` quando o início da
/// sala foi alcançado.
pub async fn paginate_backwards(room_id: String, count: u16) -> Result<bool, MatrixError> {
    let timeline = sync_runtime::timeline(&room_id).await?;
    Ok(timeline.paginate_backwards(count).await?)
}

/// Enfileira uma mensagem de texto. O resultado do envio chega pelo stream
/// da timeline (`SendStateDto`).
pub async fn send_text(room_id: String, body: String) -> Result<(), MatrixError> {
    let timeline = sync_runtime::timeline(&room_id).await?;
    timeline
        .send(RoomMessageEventContent::text_plain(body).into())
        .await?;
    Ok(())
}

/// Tenta reenviar uma mensagem que falhou, identificada pelo ID da transação.
pub async fn retry_send(room_id: String, transaction_id: String) -> Result<(), MatrixError> {
    let timeline = sync_runtime::timeline(&room_id).await?;
    let handle = timeline
        .items()
        .await
        .iter()
        .filter_map(|item| item.as_event())
        .find(|event| event.transaction_id().map(|t| t.as_str()) == Some(&transaction_id))
        .and_then(EventTimelineItem::local_echo_send_handle)
        .ok_or_else(|| {
            MatrixError::new(MatrixErrorKind::Unknown, "message is no longer pending")
        })?;

    // Erros irrecuperáveis "travam" o item; erros de rede desativam a fila da
    // sala. Destravar o item e reativar a fila cobre os dois casos.
    handle
        .unwedge()
        .await
        .map_err(|e| MatrixError::new(MatrixErrorKind::Unknown, e.to_string()))?;
    timeline.room().send_queue().set_enabled(true);
    Ok(())
}

/// Marca a sala como lida até a mensagem mais recente.
pub async fn mark_as_read(room_id: String) -> Result<(), MatrixError> {
    let timeline = sync_runtime::timeline(&room_id).await?;
    timeline.mark_as_read(ReceiptType::Read).await?;
    Ok(())
}

fn to_message(item: &std::sync::Arc<TimelineItem>) -> Option<MessageDto> {
    let event = item.as_event()?;
    let (kind, body, event_type) = classify(event.content())?;

    let id = event
        .event_id()
        .map(ToString::to_string)
        .or_else(|| event.transaction_id().map(ToString::to_string))?;
    let sender_name = match event.sender_profile() {
        TimelineDetails::Ready(profile) => profile.display_name.clone(),
        _ => None,
    }
    .unwrap_or_else(|| event.sender().to_string());

    Some(MessageDto {
        id,
        sender_id: event.sender().to_string(),
        sender_name,
        kind,
        body,
        event_type,
        timestamp_ms: i64::from(event.timestamp().0),
        is_own: event.is_own(),
        send_state: send_state(event.send_state()),
    })
}

type Classified = (MessageKindDto, Option<String>, Option<String>);

/// `None` para itens que não são mensagens.
fn classify(content: &TimelineItemContent) -> Option<Classified> {
    let unsupported = |event_type: &str| {
        Some((
            MessageKindDto::Unsupported,
            None,
            Some(event_type.to_owned()),
        ))
    };

    match content {
        TimelineItemContent::MsgLike(msg_like) => match &msg_like.kind {
            MsgLikeKind::Message(message) => Some(classify_msgtype(message.msgtype())),
            MsgLikeKind::Redacted => Some((MessageKindDto::Redacted, None, None)),
            MsgLikeKind::UnableToDecrypt(_) => Some((MessageKindDto::Undecryptable, None, None)),
            MsgLikeKind::Sticker(_) => unsupported("m.sticker"),
            MsgLikeKind::Poll(_) => unsupported("m.poll.start"),
            MsgLikeKind::LiveLocation(_) => unsupported("m.beacon_info"),
            MsgLikeKind::Other(other) => unsupported(&other.event_type().to_string()),
        },
        TimelineItemContent::FailedToParseMessageLike { event_type, .. } => {
            unsupported(&event_type.to_string())
        }
        _ => None,
    }
}

fn classify_msgtype(msgtype: &MessageType) -> Classified {
    match msgtype {
        MessageType::Text(text) => (MessageKindDto::Text, Some(text.body.clone()), None),
        MessageType::Notice(notice) => (MessageKindDto::Text, Some(notice.body.clone()), None),
        MessageType::Emote(emote) => (MessageKindDto::Text, Some(emote.body.clone()), None),
        other => (
            MessageKindDto::Unsupported,
            None,
            Some(other.msgtype().to_owned()),
        ),
    }
}

/// Eventos remotos não têm estado de envio: já estão no servidor.
fn send_state(state: Option<&EventSendState>) -> SendStateDto {
    match state {
        None | Some(EventSendState::Sent { .. }) => SendStateDto::Sent,
        Some(EventSendState::NotSentYet { .. }) => SendStateDto::Sending,
        Some(EventSendState::SendingFailed { .. }) => SendStateDto::Failed,
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::events::room::message::{
        ImageMessageEventContent, NoticeMessageEventContent,
    };

    use super::*;

    #[test]
    fn text_and_notice_messages_carry_their_body() {
        assert_eq!(
            classify_msgtype(&MessageType::text_plain("olá")),
            (MessageKindDto::Text, Some("olá".to_owned()), None)
        );
        assert_eq!(
            classify_msgtype(&MessageType::Notice(NoticeMessageEventContent::plain(
                "aviso"
            ))),
            (MessageKindDto::Text, Some("aviso".to_owned()), None)
        );
    }

    #[test]
    fn other_msgtypes_are_unsupported_with_their_type() {
        let image = MessageType::Image(ImageMessageEventContent::plain(
            "foto.png".to_owned(),
            "mxc://matrix.org/abc".into(),
        ));

        assert_eq!(
            classify_msgtype(&image),
            (
                MessageKindDto::Unsupported,
                None,
                Some("m.image".to_owned())
            )
        );
    }

    #[test]
    fn maps_send_states() {
        assert_eq!(send_state(None), SendStateDto::Sent);
        assert_eq!(
            send_state(Some(&EventSendState::NotSentYet { progress: None })),
            SendStateDto::Sending
        );
    }
}
