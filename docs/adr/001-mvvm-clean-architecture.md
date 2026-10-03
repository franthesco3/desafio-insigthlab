# ADR 001 — MVVM + Clean Architecture, organização feature-first

**Status:** aceito

## Contexto

O desafio exige MVVM, princípios SOLID e um cliente que cresça (mídia, SSO, notificações) sem reescrever o núcleo. A comunicação com o Matrix acontece em Rust, atrás de uma ponte FFI — uma fronteira cara de mockar se vazar para a lógica de negócio.

## Decisão

- **MVVM na apresentação:** Views (widgets) só renderizam e repassam eventos; ViewModels (`GetxController`) expõem estado observável e comandos; o Model são as entidades do domínio.
- **Clean Architecture nas camadas:** domínio (Dart puro: entidades, interfaces de repositório, casos de uso) ← dados (repositórios, data sources, mappers) ← nativo (Rust). As dependências de código apontam para o domínio.
- **Feature-first:** `lib/features/{auth,rooms,chat,home}/{domain,data,presentation}` e um `core/` compartilhado. `home` é o *shell* autenticado que compõe `rooms` e `chat`; nenhuma outra feature importa a apresentação de outra.
- **Um caso de uso por intenção do usuário**, com um único método `call`, mesmo quando só delega ao repositório: ali ficam as validações (ex.: tamanho da mensagem, quem pode ser reenviada).

## Consequências

- Domínio e ViewModels são testados sem Flutter engine e sem Rust (mocks das interfaces) — a maior parte da suíte roda em segundos.
- Mais arquivos por funcionalidade (entidade, interface, implementação, caso de uso, ViewModel, binding). Aceitamos o custo pela previsibilidade: cada arquivo tem um papel único.
- Casos de uso finos podem parecer cerimoniais; em troca, regras novas têm lugar óbvio para entrar.
