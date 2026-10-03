//! Ciclo de vida do sync e das tarefas que alimentam os streams do Dart.
//!
//! O `SyncService` é criado sob demanda pelo primeiro `watch_*` e encerrado
//! no logout, junto com todas as tarefas e timelines registradas aqui.

use std::{
    collections::HashMap,
    sync::{Arc, LazyLock},
};

use matrix_sdk::ruma::{OwnedRoomId, RoomId};
use matrix_sdk_ui::{sync_service::SyncService, timeline::RoomExt, Timeline};
use tokio::{sync::Mutex, task::AbortHandle};

use crate::{
    api::error::{MatrixError, MatrixErrorKind},
    client_holder,
};

#[derive(Default)]
struct SyncRuntime {
    service: Option<Arc<SyncService>>,
    tasks: Vec<AbortHandle>,
    /// Uma timeline por sala aberta, compartilhada entre stream, paginação e
    /// envio.
    timelines: HashMap<OwnedRoomId, Arc<Timeline>>,
}

static RUNTIME: LazyLock<Mutex<SyncRuntime>> = LazyLock::new(Default::default);

/// Retorna o `SyncService` da sessão ativa, criando e iniciando-o se preciso.
pub(crate) async fn service() -> Result<Arc<SyncService>, MatrixError> {
    let mut runtime = RUNTIME.lock().await;
    if let Some(service) = &runtime.service {
        return Ok(service.clone());
    }

    let client = client_holder::get()?;
    // O event cache calcula a última mensagem de cada sala (prévia na lista)
    // e alimenta a timeline.
    client
        .event_cache()
        .subscribe()
        .map_err(|e| MatrixError::new(MatrixErrorKind::Unknown, e.to_string()))?;

    let service = SyncService::builder(client)
        .with_offline_mode()
        .build()
        .await
        .map_err(|e| MatrixError::new(MatrixErrorKind::Unknown, e.to_string()))?;
    let service = Arc::new(service);
    service.start().await;

    runtime.service = Some(service.clone());
    Ok(service)
}

/// Retorna a timeline da sala, criando-a na primeira chamada. Inicia o sync
/// se necessário, pois é ele que alimenta a timeline.
pub(crate) async fn timeline(room_id: &str) -> Result<Arc<Timeline>, MatrixError> {
    let room_id = RoomId::parse(room_id)
        .map_err(|e| MatrixError::new(MatrixErrorKind::RoomNotFound, e.to_string()))?;
    service().await?;

    let mut runtime = RUNTIME.lock().await;
    if let Some(timeline) = runtime.timelines.get(&room_id) {
        return Ok(timeline.clone());
    }

    let room = client_holder::get()?
        .get_room(&room_id)
        .ok_or_else(|| MatrixError::new(MatrixErrorKind::RoomNotFound, room_id.to_string()))?;
    let timeline = Arc::new(
        room.timeline()
            .await
            .map_err(|e| MatrixError::new(MatrixErrorKind::Unknown, e.to_string()))?,
    );
    runtime.timelines.insert(room_id, timeline.clone());
    Ok(timeline)
}

/// Registra uma tarefa para ser cancelada no logout.
pub(crate) async fn track(task: AbortHandle) {
    let mut runtime = RUNTIME.lock().await;
    runtime.tasks.retain(|t| !t.is_finished());
    runtime.tasks.push(task);
}

/// Cancela as tarefas e para o sync. Seguro de chamar sem sessão ativa.
pub(crate) async fn shutdown() {
    let (service, tasks) = {
        let mut runtime = RUNTIME.lock().await;
        runtime.timelines.clear();
        (runtime.service.take(), std::mem::take(&mut runtime.tasks))
    };
    for task in tasks {
        task.abort();
    }
    if let Some(service) = service {
        service.stop().await;
    }
}
