use flutter_rust_bridge::for_generated::anyhow;
use matrix_sdk::{ruma::api::error::ErrorKind, ClientBuildError, HttpError};

use crate::api::error::{MatrixError, MatrixErrorKind};

impl MatrixError {
    pub(crate) fn new(kind: MatrixErrorKind, message: impl Into<String>) -> Self {
        Self {
            kind,
            message: message.into(),
        }
    }

    /// Converte para o único tipo de erro que o FRB entrega em streams
    /// (`AnyhowException` no Dart). O tipo vai codificado na mensagem, e o
    /// `guardNativeStream` do Dart o reconstrói.
    pub(crate) fn into_stream_error(self) -> anyhow::Error {
        anyhow::anyhow!("{STREAM_ERROR_PREFIX}{:?}:{}", self.kind, self.message)
    }
}

/// Precisa ser igual ao `_streamErrorPrefix` de `native_call.dart`.
const STREAM_ERROR_PREFIX: &str = "matrix_error:";

impl From<&HttpError> for MatrixError {
    fn from(error: &HttpError) -> Self {
        let kind = match (error, error.client_api_error_kind()) {
            (_, Some(ErrorKind::UnknownToken(_))) => MatrixErrorKind::SessionExpired,
            (_, Some(ErrorKind::Forbidden | ErrorKind::UserDeactivated)) => {
                MatrixErrorKind::InvalidCredentials
            }
            (_, Some(_)) => MatrixErrorKind::Unknown,
            (HttpError::Cached(inner), None) => return Self::from(inner.as_ref()),
            (HttpError::Reqwest(_), None) => MatrixErrorKind::Network,
            // Resposta HTTP que não segue o formato Matrix: provavelmente não é
            // um homeserver (ex.: um site comum).
            (HttpError::Api(_), None) => MatrixErrorKind::HomeserverUnreachable,
            _ => MatrixErrorKind::Unknown,
        };
        Self::new(kind, error.to_string())
    }
}

impl From<HttpError> for MatrixError {
    fn from(error: HttpError) -> Self {
        Self::from(&error)
    }
}

impl From<matrix_sdk::Error> for MatrixError {
    fn from(error: matrix_sdk::Error) -> Self {
        match error {
            matrix_sdk::Error::Http(http) => Self::from(http.as_ref()),
            matrix_sdk::Error::AuthenticationRequired => {
                Self::new(MatrixErrorKind::NotLoggedIn, error.to_string())
            }
            other => Self::new(MatrixErrorKind::Unknown, other.to_string()),
        }
    }
}

impl From<ClientBuildError> for MatrixError {
    fn from(error: ClientBuildError) -> Self {
        match error {
            ClientBuildError::Http(http) => Self::from(&http),
            ClientBuildError::SqliteStore(_) => {
                Self::new(MatrixErrorKind::Storage, error.to_string())
            }
            ClientBuildError::AutoDiscovery(_)
            | ClientBuildError::InvalidServerName
            | ClientBuildError::Url(_) => {
                Self::new(MatrixErrorKind::HomeserverUnreachable, error.to_string())
            }
            other => Self::new(MatrixErrorKind::Unknown, other.to_string()),
        }
    }
}

impl From<std::io::Error> for MatrixError {
    fn from(error: std::io::Error) -> Self {
        Self::new(MatrixErrorKind::Storage, error.to_string())
    }
}

impl From<matrix_sdk_ui::timeline::Error> for MatrixError {
    fn from(error: matrix_sdk_ui::timeline::Error) -> Self {
        match error {
            matrix_sdk_ui::timeline::Error::Sdk(sdk) => Self::from(sdk),
            other => Self::new(MatrixErrorKind::Unknown, other.to_string()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stream_error_encodes_kind_and_message() {
        let error = MatrixError::new(MatrixErrorKind::RoomNotFound, "!x:y").into_stream_error();

        assert_eq!(format!("{error:?}"), "matrix_error:RoomNotFound:!x:y");
    }
}
