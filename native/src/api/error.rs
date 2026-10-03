//! Erro único exposto ao Dart.
//!
//! Em vez de vazar os vários tipos de erro do `matrix-sdk`, toda falha é
//! convertida (em `crate::error_mapping`) para um [`MatrixErrorKind`] estável,
//! que a camada de dados do Dart traduz para `Failure`.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MatrixErrorKind {
    /// Sem conexão, DNS ou timeout.
    Network,
    /// O endereço não responde como um homeserver Matrix.
    HomeserverUnreachable,
    /// Usuário ou senha incorretos.
    InvalidCredentials,
    /// Token revogado ou expirado.
    SessionExpired,
    /// Operação que exige sessão chamada sem login.
    NotLoggedIn,
    /// A sala não existe ou o usuário não participa dela.
    RoomNotFound,
    /// Falha ao abrir ou apagar o banco local.
    Storage,
    Unknown,
}

#[derive(Debug)]
pub struct MatrixError {
    pub kind: MatrixErrorKind,
    /// Detalhe técnico para log. Nunca contém tokens ou senhas.
    pub message: String,
}
