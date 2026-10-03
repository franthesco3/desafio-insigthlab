//! Guarda o `Client` da sessão ativa.
//!
//! O app tem uma única conta por vez, então um slot global basta. `Client` é
//! um handle barato de clonar (`Arc` interno): as funções da API pegam um
//! clone e liberam o lock antes de qualquer `await`.

use std::sync::{LazyLock, RwLock};

use matrix_sdk::Client;

use crate::api::error::{MatrixError, MatrixErrorKind};

static CLIENT: LazyLock<RwLock<Option<Client>>> = LazyLock::new(|| RwLock::new(None));

pub(crate) fn set(client: Client) {
    *CLIENT
        .write()
        .unwrap_or_else(|poisoned| poisoned.into_inner()) = Some(client);
}

pub(crate) fn take() -> Option<Client> {
    CLIENT
        .write()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .take()
}

pub(crate) fn get() -> Result<Client, MatrixError> {
    CLIENT
        .read()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .clone()
        .ok_or_else(|| MatrixError::new(MatrixErrorKind::NotLoggedIn, "no active session"))
}
