// O future de paginação do matrix-sdk-ui excede o limite padrão (128).
#![recursion_limit = "256"]

pub mod api;
mod client_holder;
mod error_mapping;
mod frb_generated;
mod sync_runtime;
