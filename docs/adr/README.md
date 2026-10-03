# Registro de decisões de arquitetura (ADRs)

Cada arquivo registra uma decisão relevante no formato **Contexto → Decisão → Consequências**. ADRs não são reescritos: uma decisão revista ganha um novo ADR que substitui o anterior.

| ADR | Decisão | Status |
|---|---|---|
| [001](001-mvvm-clean-architecture.md) | MVVM + Clean Architecture, organização feature-first | Aceito |
| [002](002-getx-restrito-a-apresentacao.md) | GetX restrito à apresentação e ao *composition root* | Aceito |
| [003](003-facade-rust-propria.md) | Facade Rust própria sobre o `matrix-rust-sdk` | Aceito |
| [004](004-matrix-sdk-ui.md) | `matrix-sdk-ui` (`SyncService`/`RoomListService`/`Timeline`) para sync e local echo | Aceito |
| [005](005-sessao-no-cofre-e-store-criptografado.md) | Sessão no cofre do SO + store SQLite criptografado com passphrase | Aceito |
| [006](006-result-e-failure-selados.md) | `Result<T>` + `sealed Failure` em vez de exceções entre camadas | Aceito |
| [007](007-erros-tipados-em-streams-frb.md) | Erros tipados em streams codificados sobre `AnyhowException` | Aceito |
