# ADR 003 — Facade Rust própria sobre o matrix-rust-sdk

**Status:** aceito

## Contexto

O `matrix-rust-sdk` está em versões 0.x, com API extensa e em evolução. O Flutter Rust Bridge (FRB) gera bindings para tudo o que for público no crate de entrada; expor tipos do SDK diretamente geraria uma superfície enorme, instável e difícil de mapear no Dart.

## Decisão

- O crate `native/` expõe uma **API pequena e estável** em `native/src/api/` (`auth`, `rooms`, `timeline`, `error`, `health`), com **DTOs próprios** (`SessionDto`, `RoomSummaryDto`, `MessageDto`…) e enums simples.
- Estado global mínimo: `client_holder` (o `Client` da sessão) e `sync_runtime` (o `SyncService`, as timelines abertas e as tarefas que alimentam streams, encerradas no logout).
- No Dart, só os `*NativeDataSource` e `core/native` importam código gerado; *mappers* convertem DTOs em entidades. DTOs nunca chegam ao domínio.
- Enums com dados foram evitados nos DTOs (ex.: `MessageDto` usa `kind` + campos opcionais), porque o FRB os geraria como classes `freezed`, exigindo `build_runner` só para isso.

## Consequências

- Atualizar o SDK afeta apenas `native/src`; a API vista pelo Dart muda só quando queremos.
- Cada nova capacidade exige escrever a função na facade, o DTO e o mapper — trabalho extra deliberado.
- Testes Rust cobrem as conversões (classificação de mensagens, estados de envio, mapeamento de erros) sem rede.
