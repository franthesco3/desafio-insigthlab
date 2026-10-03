# ADR 006 — Result<T> e Failure selados em vez de exceções entre camadas

**Status:** aceito

## Contexto

Erros acontecem em várias fronteiras (rede, homeserver, cofre, banco local, validação) e precisam virar mensagens claras na UI. Exceções propagadas livremente são invisíveis na assinatura dos métodos e fáceis de esquecer de tratar.

## Decisão

- Repositórios e casos de uso retornam `Result<T>` (`sealed`: `Ok` / `Err`) e **nunca lançam**. Streams seguem a mesma regra: `Stream<Result<T>>`.
- `Failure` é uma `sealed class` (`NetworkFailure`, `InvalidCredentialsFailure`, `SessionExpiredFailure`, `RoomNotFoundFailure`, `ValidationFailure(reason)`, `UnexpectedFailure`…), sem texto de UI — só um `details` técnico para log.
- Conversão em um único ponto por fronteira: Rust `matrix_sdk::Error` → `MatrixError { kind }` → `NativeException` (`guardNative`/`guardNativeStream`) → `Failure` (`guardResult`/`asResults`, que também registram o erro no `AppLogger`).
- A apresentação traduz cada `Failure` em texto (`failure_messages.dart`) com `switch` exaustivo.

## Consequências

- O compilador obriga o tratamento de todos os casos; uma nova `Failure` aponta cada `switch` que precisa ser atualizado.
- Um pouco de verbosidade (`switch` sobre `Ok`/`Err`) em troca de fluxos de erro explícitos e testáveis.
- Erros de programação continuam sendo exceções; só são convertidos em `UnexpectedFailure` na fronteira dos repositórios, com registro em log.
