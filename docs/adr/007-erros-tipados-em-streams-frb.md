# ADR 007 — Erros tipados em streams codificados sobre AnyhowException

**Status:** aceito

## Contexto

As funções Rust que alimentam streams (`watch_rooms`, `watch_sync_state`, `watch_timeline`) recebem um `StreamSink` e enviam erros com `sink.add_error`. No FRB 2.13, o lado Dart decodifica **todo** erro de `StreamSink` como `AnyhowException`, qualquer que seja o tipo enviado pelo Rust. Enviar um `MatrixError` resultava em uma `AnyhowException` com bytes ilegíveis, e a UI caía sempre em "Algo deu errado". Um `Err` retornado pela própria função de stream também não chega ao `Stream` do Dart.

## Decisão

- No Rust, erros de stream são enviados como `MatrixError::into_stream_error()`, um `anyhow::Error` com a mensagem `matrix_error:<Kind>:<detalhe>` (ex.: `matrix_error:RoomNotFound:!abc:matrix.org`).
- No Dart, `guardNativeStream` reconhece `AnyhowException` com esse prefixo e reconstrói a `NativeException` tipada (`parseStreamError`). Formatos desconhecidos viram `NativeErrorKind.unknown`.
- O prefixo é uma constante duplicada nos dois lados (`STREAM_ERROR_PREFIX` / `_streamErrorPrefix`), com testes em ambos e testes de integração da ponte cobrindo o caminho real.

## Consequências

- Streams e `Future`s chegam ao domínio com os mesmos `Failure` tipados.
- Contrato baseado em string: renomear uma variante de `MatrixErrorKind` exige regenerar os bindings (o que já acontece) e mantém o parse funcionando, porque o nome vem do enum gerado. Já mudar o formato exige alterar os dois lados juntos.
- Se uma versão futura do FRB suportar erros tipados em `StreamSink`, este ADR pode ser substituído e o parse removido.
