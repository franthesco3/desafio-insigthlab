//! Funções de diagnóstico da ponte Dart ⇄ Rust.
//!
//! Servem para confirmar, logo na inicialização, que a biblioteca nativa foi
//! carregada e que o `matrix-sdk` está linkado corretamente.

use matrix_sdk::ruma::UserId;

/// Informações sobre a camada nativa.
pub struct NativeInfo {
    pub crate_version: String,
}

#[flutter_rust_bridge::frb(sync)]
pub fn native_info() -> NativeInfo {
    NativeInfo {
        crate_version: env!("CARGO_PKG_VERSION").to_owned(),
    }
}

/// Valida um Matrix user ID (`@usuario:servidor`) usando o parser do SDK.
#[flutter_rust_bridge::frb(sync)]
pub fn is_valid_user_id(user_id: String) -> bool {
    UserId::parse(user_id).is_ok()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_well_formed_user_id() {
        assert!(is_valid_user_id("@alice:matrix.org".to_owned()));
    }

    #[test]
    fn rejects_malformed_user_id() {
        assert!(!is_valid_user_id("alice".to_owned()));
        assert!(!is_valid_user_id("@alice".to_owned()));
    }
}
