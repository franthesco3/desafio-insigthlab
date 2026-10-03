//! Sincronização e lista de salas.

use std::collections::HashSet;

use futures_util::{pin_mut, StreamExt};
use matrix_sdk::{
    deserialized_responses::TimelineEvent, latest_events::LatestEventValue, ruma::OwnedRoomId,
};
use matrix_sdk_ui::{
    eyeball_im::Vector,
    room_list_service::{filters, RoomListItem, State as RoomListState},
    sync_service::State as SyncServiceState,
};

use crate::{
    api::error::{MatrixError, MatrixErrorKind},
    client_holder,
    frb_generated::StreamSink,
    sync_runtime,
};

/// Quantidade de salas carregadas. Clientes desktop costumam exibir todas.
const ROOM_LIST_PAGE_SIZE: usize = 500;

pub struct RoomSummaryDto {
    pub room_id: String,
    pub name: String,
    pub last_message_preview: Option<String>,
    /// Timestamp da última mensagem, em milissegundos desde a época Unix.
    pub last_activity_ms: Option<i64>,
    pub unread_count: u32,
    pub is_encrypted: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SyncStateDto {
    Idle,
    Syncing,
    Running,
    Offline,
    Error,
}

/// Emite o estado do sync sempre que ele muda. Inicia o sync se necessário.
///
/// Erros são enviados pelo próprio stream (`add_error`): um `Err` retornado
/// por funções de stream não chega ao `Stream` do Dart. Ver
/// `MatrixError::into_stream_error`.
pub async fn watch_sync_state(sink: StreamSink<SyncStateDto>) {
    let service = match sync_runtime::service().await {
        Ok(service) => service,
        Err(error) => {
            let _ = sink.add_error(error.into_stream_error());
            return;
        }
    };

    let task = tokio::spawn(async move {
        let mut sync_states = service.state();
        let mut list_states = service.room_list_service().state();
        let mut sync_state = sync_states.get();
        let mut list_state = list_states.get();

        loop {
            if sink.add(combine_states(&sync_state, &list_state)).is_err() {
                break; // O Dart cancelou a assinatura.
            }
            tokio::select! {
                Some(state) = sync_states.next() => sync_state = state,
                Some(state) = list_states.next() => list_state = state,
                else => break,
            }
        }
    });
    sync_runtime::track(task.abort_handle()).await;
}

/// Emite a lista completa de salas (exceto as que o usuário saiu) a cada
/// mudança. Inicia o sync se necessário.
pub async fn watch_rooms(sink: StreamSink<Vec<RoomSummaryDto>>) {
    let setup = async {
        let service = sync_runtime::service().await?;
        let client = client_holder::get()?;
        let all_rooms = service
            .room_list_service()
            .all_rooms()
            .await
            .map_err(|e| MatrixError::new(MatrixErrorKind::Unknown, e.to_string()))?;
        Ok::<_, MatrixError>((client, all_rooms))
    };
    let (client, all_rooms) = match setup.await {
        Ok(value) => value,
        Err(error) => {
            let _ = sink.add_error(error.into_stream_error());
            return;
        }
    };

    let task = tokio::spawn(async move {
        let (diffs, controller) = all_rooms.entries_with_dynamic_adapters(ROOM_LIST_PAGE_SIZE);
        controller.set_filter(Box::new(filters::new_filter_non_left()));
        pin_mut!(diffs);

        let latest_events = client.latest_events().await;
        let mut listened: HashSet<OwnedRoomId> = HashSet::new();
        let mut rooms: Vector<RoomListItem> = Vector::new();

        while let Some(batch) = diffs.next().await {
            for diff in batch {
                diff.apply(&mut rooms);
            }
            for room in &rooms {
                // Necessário para o SDK calcular a prévia da última mensagem.
                if listened.insert(room.room_id().to_owned()) {
                    let _ = latest_events.listen_to_room(room.room_id()).await;
                }
            }
            if sink.add(rooms.iter().map(summarize).collect()).is_err() {
                break;
            }
        }
    });
    sync_runtime::track(task.abort_handle()).await;
}

fn summarize(room: &RoomListItem) -> RoomSummaryDto {
    let name = room
        .cached_display_name()
        .map(|name| name.to_string())
        .or_else(|| room.name())
        .unwrap_or_else(|| room.room_id().to_string());

    RoomSummaryDto {
        room_id: room.room_id().to_string(),
        name,
        last_message_preview: preview(&room.latest_event()),
        last_activity_ms: room.latest_event_timestamp().map(|ts| i64::from(ts.0)),
        unread_count: u32::try_from(room.unread_notification_counts().notification_count)
            .unwrap_or(u32::MAX),
        is_encrypted: room.encryption_state().is_encrypted(),
    }
}

fn preview(latest: &LatestEventValue) -> Option<String> {
    match latest {
        LatestEventValue::Remote(event) => message_body(event),
        _ => None,
    }
}

/// Corpo de texto de um `m.room.message`; outros tipos não geram prévia.
fn message_body(event: &TimelineEvent) -> Option<String> {
    let raw = event.raw();
    let event_type = raw.get_field::<String>("type").ok().flatten()?;
    if event_type != "m.room.message" {
        return None;
    }
    let content = raw
        .get_field::<serde_json::Value>("content")
        .ok()
        .flatten()?;
    content.get("body")?.as_str().map(str::to_owned)
}

fn combine_states(sync: &SyncServiceState, list: &RoomListState) -> SyncStateDto {
    match sync {
        SyncServiceState::Idle | SyncServiceState::Terminated => SyncStateDto::Idle,
        SyncServiceState::Offline => SyncStateDto::Offline,
        SyncServiceState::Error(_) => SyncStateDto::Error,
        SyncServiceState::Running => match list {
            RoomListState::Running => SyncStateDto::Running,
            RoomListState::Error { .. } => SyncStateDto::Error,
            RoomListState::Terminated { .. } => SyncStateDto::Idle,
            RoomListState::Init | RoomListState::SettingUp | RoomListState::Recovering => {
                SyncStateDto::Syncing
            }
        },
    }
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::serde::Raw;

    use super::*;

    fn event(json: serde_json::Value) -> TimelineEvent {
        TimelineEvent::from_plaintext(Raw::new(&json).unwrap().cast_unchecked())
    }

    #[test]
    fn extracts_body_from_text_message() {
        let event = event(serde_json::json!({
            "type": "m.room.message",
            "event_id": "$1",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1,
            "content": { "msgtype": "m.text", "body": "olá" },
        }));

        assert_eq!(message_body(&event).as_deref(), Some("olá"));
    }

    #[test]
    fn ignores_non_message_events() {
        let event = event(serde_json::json!({
            "type": "m.room.member",
            "event_id": "$1",
            "sender": "@alice:matrix.org",
            "origin_server_ts": 1,
            "state_key": "@alice:matrix.org",
            "content": { "membership": "join" },
        }));

        assert_eq!(message_body(&event), None);
    }

    #[test]
    fn running_sync_reports_syncing_until_room_list_is_ready() {
        assert_eq!(
            combine_states(&SyncServiceState::Running, &RoomListState::SettingUp),
            SyncStateDto::Syncing
        );
        assert_eq!(
            combine_states(&SyncServiceState::Running, &RoomListState::Running),
            SyncStateDto::Running
        );
        assert_eq!(
            combine_states(&SyncServiceState::Offline, &RoomListState::Running),
            SyncStateDto::Offline
        );
    }
}
