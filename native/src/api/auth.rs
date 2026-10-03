//! Autenticação: login, restauração e logout de sessão.

use std::path::Path;

use matrix_sdk::{
    authentication::matrix::MatrixSession,
    ruma::{OwnedDeviceId, OwnedUserId},
    Client, SessionMeta, SessionTokens,
};

use crate::{
    api::error::{MatrixError, MatrixErrorKind},
    client_holder, sync_runtime,
};

const DEVICE_DISPLAY_NAME: &str = "Matrix Desktop";

/// Dados necessários para restaurar a sessão. O Dart guarda esta estrutura
/// no cofre do sistema operacional.
pub struct SessionDto {
    pub user_id: String,
    pub device_id: String,
    pub access_token: String,
    pub refresh_token: Option<String>,
    /// URL real do homeserver, já resolvida via `.well-known`.
    pub homeserver_url: String,
}

// Implementação manual para nunca imprimir tokens em logs ou panics.
impl std::fmt::Debug for SessionDto {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SessionDto")
            .field("user_id", &self.user_id)
            .field("device_id", &self.device_id)
            .field("homeserver_url", &self.homeserver_url)
            .finish_non_exhaustive()
    }
}

/// Autentica com usuário e senha.
///
/// `homeserver` pode ser um server name (`matrix.org`) ou uma URL; a
/// descoberta via `.well-known` é feita pelo SDK. O banco local em
/// `store_path` é recriado do zero e criptografado com `passphrase`.
pub async fn login(
    homeserver: String,
    username: String,
    password: String,
    store_path: String,
    passphrase: String,
) -> Result<SessionDto, MatrixError> {
    sync_runtime::shutdown().await;
    // Um store de outra conta/dispositivo impediria a abertura do client.
    remove_store(&store_path)?;

    let client = Client::builder()
        .server_name_or_homeserver_url(&homeserver)
        .sqlite_store(&store_path, Some(&passphrase))
        .build()
        .await?;

    client
        .matrix_auth()
        .login_username(&username, &password)
        .initial_device_display_name(DEVICE_DISPLAY_NAME)
        .await?;

    let session = client.matrix_auth().session().ok_or_else(|| {
        MatrixError::new(
            MatrixErrorKind::Unknown,
            "login succeeded without a session",
        )
    })?;
    let dto = SessionDto {
        user_id: session.meta.user_id.to_string(),
        device_id: session.meta.device_id.to_string(),
        access_token: session.tokens.access_token,
        refresh_token: session.tokens.refresh_token,
        homeserver_url: client.homeserver().to_string(),
    };

    client_holder::set(client);
    Ok(dto)
}

/// Restaura uma sessão salva e confirma com o servidor que o token é válido.
///
/// Sem rede, a sessão é restaurada mesmo assim: o sync tentará reconectar.
pub async fn restore_session(
    session: SessionDto,
    store_path: String,
    passphrase: String,
) -> Result<(), MatrixError> {
    sync_runtime::shutdown().await;
    let user_id = OwnedUserId::try_from(session.user_id)
        .map_err(|e| MatrixError::new(MatrixErrorKind::SessionExpired, e.to_string()))?;

    let client = Client::builder()
        .homeserver_url(&session.homeserver_url)
        .sqlite_store(&store_path, Some(&passphrase))
        .build()
        .await?;

    client
        .restore_session(MatrixSession {
            meta: SessionMeta {
                user_id,
                device_id: OwnedDeviceId::from(session.device_id),
            },
            tokens: SessionTokens {
                access_token: session.access_token,
                refresh_token: session.refresh_token,
            },
        })
        .await?;

    if let Err(error) = client.whoami().await {
        let error = MatrixError::from(error);
        if error.kind != MatrixErrorKind::Network {
            return Err(error);
        }
    }

    client_holder::set(client);
    Ok(())
}

/// Encerra a sessão no servidor e apaga o banco local.
///
/// A limpeza local acontece mesmo que o servidor não responda: o usuário
/// pediu para sair e não pode ficar preso por falta de rede.
pub async fn logout(store_path: String) -> Result<(), MatrixError> {
    sync_runtime::shutdown().await;
    if let Some(client) = client_holder::take() {
        // Falha aqui significa token já inválido ou servidor fora do ar; em
        // ambos os casos não há o que o usuário possa fazer.
        let _ = client.logout().await;
    }
    remove_store(&store_path)
}

fn remove_store(store_path: &str) -> Result<(), MatrixError> {
    let path = Path::new(store_path);
    if path.exists() {
        std::fs::remove_dir_all(path)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_store() -> String {
        let dir = std::env::temp_dir().join(format!("matrix_native_test_{}", std::process::id()));
        dir.to_string_lossy().into_owned()
    }

    #[tokio::test]
    async fn logout_without_session_removes_local_store() {
        let store = temp_store();
        std::fs::create_dir_all(&store).unwrap();
        std::fs::write(Path::new(&store).join("db.sqlite3"), b"x").unwrap();

        logout(store.clone()).await.unwrap();

        assert!(!Path::new(&store).exists());
    }

    #[test]
    fn debug_output_hides_tokens() {
        let session = SessionDto {
            user_id: "@alice:matrix.org".into(),
            device_id: "DEVICE".into(),
            access_token: "secret-access".into(),
            refresh_token: Some("secret-refresh".into()),
            homeserver_url: "https://matrix.org".into(),
        };

        let output = format!("{session:?}");

        assert!(!output.contains("secret"));
    }

    #[tokio::test]
    async fn restore_rejects_malformed_user_id() {
        let session = SessionDto {
            user_id: "not-a-user-id".into(),
            device_id: "DEVICE".into(),
            access_token: "token".into(),
            refresh_token: None,
            homeserver_url: "https://example.org".into(),
        };

        let error = restore_session(session, temp_store(), "pass".into())
            .await
            .unwrap_err();

        assert_eq!(error.kind, MatrixErrorKind::SessionExpired);
    }

    /// Requer internet: valida descoberta via `.well-known` e o mapeamento de
    /// erro de senha incorreta. Rodar com `cargo test -- --ignored`.
    #[tokio::test]
    #[ignore]
    async fn login_with_wrong_password_on_matrix_org_maps_to_invalid_credentials() {
        let store = format!("{}_login", temp_store());
        let error = login(
            "matrix.org".into(),
            "@matrix-desktop-nonexistent-user:matrix.org".into(),
            "wrong-password".into(),
            store.clone(),
            "pass".into(),
        )
        .await
        .unwrap_err();

        let _ = std::fs::remove_dir_all(&store);
        assert_eq!(
            error.kind,
            MatrixErrorKind::InvalidCredentials,
            "{}",
            error.message
        );
    }

    /// Requer internet: um site que não é homeserver deve ser reconhecido.
    #[tokio::test]
    #[ignore]
    async fn login_on_non_matrix_server_maps_to_homeserver_unreachable() {
        let store = format!("{}_nonmatrix", temp_store());
        let error = login(
            "https://example.com".into(),
            "alice".into(),
            "pw".into(),
            store.clone(),
            "pass".into(),
        )
        .await
        .unwrap_err();

        let _ = std::fs::remove_dir_all(&store);
        assert_eq!(
            error.kind,
            MatrixErrorKind::HomeserverUnreachable,
            "{}",
            error.message
        );
    }
}
