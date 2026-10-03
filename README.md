# Matrix Desktop

Cliente de mensageria desktop (macOS, Windows, Linux) para o protocolo [Matrix](https://matrix.org), feito em Flutter. Toda a comunicação com o Matrix é implementada em Rust ([matrix-rust-sdk](https://github.com/matrix-org/matrix-rust-sdk)) e exposta ao Dart pelo [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/) v2.

## Funcionalidades

- **Login** com homeserver, usuário e senha, com mensagens claras para servidor inválido, credenciais erradas e falta de rede.
- **Sessão persistente e segura**: tokens e chave do banco local ficam no cofre do sistema operacional, e o banco do SDK é criptografado. Ao reabrir, a sessão é restaurada sem pedir senha.
- **Lista de salas em tempo real**, com avatar por iniciais, prévia e horário da última mensagem, contador de não lidas, indicador de sala criptografada e busca por nome.
- **Indicador de sincronização**: sincronizando, conectado, offline ou erro.
- **Conversa** com mensagens agrupadas por autor, divisores de dia e carregamento de mensagens antigas ao rolar para cima.
- **Envio de texto com local echo**: a mensagem aparece na hora como *enviando*, depois *enviada* ou *falhou*, com opção de reenviar.
- **Recibo de leitura** automático ao abrir a sala, o que zera o contador de não lidas.
- **Logout** que invalida o token no servidor e apaga os dados locais.
- Tema claro e escuro, seguindo o sistema.

## Documentação

- [Documento de Visão](docs/01-documento-de-visao.md): objetivos, escopo, requisitos e plano de entrega.
- [Arquitetura](docs/02-arquitetura.md): MVVM + Clean Architecture com GetX, camadas, fluxos, segurança e testes.
- [ADRs](docs/adr/README.md): registro das decisões técnicas e de seus trade-offs.

## Pré-requisitos

| Ferramenta | Versão testada |
|---|---|
| Flutter (stable) | 3.41 |
| Rust (via [rustup](https://rustup.rs)) | 1.99 |
| macOS | Xcode 26+ e CocoaPods; macOS 12+ |
| Linux | `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libsecret-1-dev` e um serviço de secrets em execução (gnome-keyring ou KWallet) |
| Windows | Visual Studio 2022 com "Desenvolvimento para desktop com C++" |
| `flutter_rust_bridge_codegen` (opcional) | 2.13.0. Só é necessário para alterar a API Rust (veja abaixo). |

> O primeiro build compila o `matrix-sdk` e leva alguns minutos. Reserve ~10 GB de disco para os artefatos de build.

## Como executar

```bash
flutter pub get
flutter run -d macos      # ou: -d windows / -d linux
```

O crate Rust (`native/`) é compilado automaticamente pelo `cargokit` durante o build do Flutter. Os bindings Dart ⇄ Rust já estão versionados em `lib/core/native/bridge/`.

### Regenerar os bindings Dart ⇄ Rust

Necessário sempre que a API pública em `native/src/api/` mudar:

```bash
cargo install flutter_rust_bridge_codegen --version 2.13.0   # uma vez
flutter_rust_bridge_codegen generate
```

## Como usar

1. Abra o app. Sem sessão salva, a tela de login aparece.
2. Informe o servidor (padrão `matrix.org`), o usuário (`alice` ou `@alice:matrix.org`) e a senha.
3. Selecione uma sala na lista à esquerda para abrir a conversa. Role para cima para carregar mensagens antigas.
4. Escreva no campo inferior e pressione **Enter** para enviar. A mensagem aparece na hora com o estado *enviando* (relógio), depois *enviada* (✓) ou *falhou*, com o botão **Tentar de novo**.
5. Ao reabrir o app, a sessão é restaurada automaticamente.
6. Use o botão **Sair**, acima da lista de salas, para encerrar a sessão e apagar os dados locais.

### Atalhos

| Atalho | Ação |
|---|---|
| `Enter` | Envia a mensagem |
| `Shift+Enter` | Quebra a linha |
| `Ctrl+K` / `⌘K` | Foca a busca de salas |

## Testes

```bash
flutter analyze                          # lints (very_good_analysis), sem avisos
flutter test                             # 136 testes unitários e de widget
flutter test integration_test -d macos   # app real + ponte Rust (login_flow_test requer internet)
(cd native && cargo clippy --all-targets -- -D warnings)
(cd native && cargo test)                # 12 testes do crate Rust
(cd native && cargo test -- --ignored)   # testes do Rust contra o matrix.org (requer internet)
```

| Camada | O que é coberto |
|---|---|
| Domínio | Casos de uso: validações e delegação ao repositório |
| Dados | Repositórios (conversão de erros em `Failure`, cofre), mappers de DTO |
| Apresentação | ViewModels (transições de estado, troca de sala, paginação, envio/reenvio, cancelamento de streams) e widgets (login, home, lista de salas, conversa, campo de mensagem) |
| Core | `Result`/`Failure`, erros nativos, redação do logger, formatação de datas |
| Rust | Classificação de mensagens, estados de envio, mapeamento de erros, estados de sync |
| Integração | Ponte FRB real: erros tipados em `Future` e em streams, login com senha errada no matrix.org |

## Estrutura do projeto

```
lib/
├── app/          # GetMaterialApp, rotas, InitialBinding, AuthGuard
├── core/         # Result/Failure, ponte nativa, logger, componentes de UI
└── features/
    ├── auth/     # login, restauração e logout   (domain / data / presentation)
    ├── rooms/    # sync e lista de salas
    ├── chat/     # timeline, paginação e envio
    └── home/     # shell autenticado que compõe rooms + chat
native/src/api/   # facade Rust exposta ao Dart (auth, rooms, timeline)
docs/             # visão, arquitetura e ADRs
```

Os detalhes estão em [Arquitetura § 3](docs/02-arquitetura.md#3-estrutura-de-pastas).

## Estado atual

| Fase | Status |
|---|---|
| 0. Esqueleto Flutter + Rust + FRB | ✅ concluída |
| 1. Domínio e contratos | ✅ concluída |
| 2. Autenticação, sessão segura, logout/restauração | ✅ concluída |
| 3. Sync e lista de salas | ✅ concluída |
| 4. Timeline e envio de mensagens | ✅ concluída |
| 5. Polimento, testes de widget, ADRs | ✅ concluída |

Todas as fases foram validadas manualmente no macOS com uma conta real no matrix.org.

## Limitações conhecidas

| Limitação | Como a arquitetura suportaria |
|---|---|
| Builds de Windows e Linux não foram validados em máquina real (código e instruções existem; só o macOS foi testado). | Nada muda no código Dart ou Rust: o `cargokit` compila o crate em cada SO, e o SQLite vai embutido para evitar diferenças entre sistemas. |
| Apenas login por senha (`m.login.password`). Servidores só com SSO/OIDC não são suportados. | Nova função na facade Rust (`matrix_auth().login_sso` ou OIDC) e novo caso de uso, mantendo o contrato do `AuthRepository`. |
| Logout sem conexão limpa os dados locais, mas o token pode continuar válido no servidor. | Guardar o token pendente no cofre e invalidá-lo na próxima vez que houver rede. |
| Apenas mensagens de texto são exibidas e enviadas. Imagens, arquivos e enquetes aparecem como "tipo de mensagem não suportado". | Nova subclasse de `MessageContent`, um novo `MessageKindDto`, um widget próprio e `send_attachment` na facade, sem alterar os tipos existentes. |
| Edições, reações, respostas e threads não são exibidas. | A `Timeline` do `matrix-sdk-ui` já agrega esses eventos. Bastaria expô-los no `MessageDto` e na entidade `Message`. |
| Não há verificação de dispositivo nem backup de chaves. Em salas criptografadas, mensagens anteriores ao login deste dispositivo aparecem como "não foi possível descriptografar". | Expor na facade a verificação interativa (`encryption().verification`) e a recuperação de chaves (`encryption().recovery()`) do SDK, com uma feature `security` própria. |
| Não há notificações nativas do sistema operacional. | Um serviço na apresentação ouvindo o `WatchRoomsUseCase` (variação do contador de não lidas). |
| Uma conta por vez. | O `client_holder` passaria de slot único para um mapa por `userId`, e o cofre guardaria uma sessão por conta. |
| Não há teste automatizado de login bem-sucedido, porque isso exigiria uma conta de teste versionada. O teste contra o matrix.org cobre o caminho de senha incorreta. | Um Synapse local via Docker no CI permitiria testar o fluxo completo (login → sala → envio). |

## Solução de problemas

- **Primeiro build demorado**: é esperado. O `matrix-sdk` e o SQLite são compilados do zero, e os builds seguintes são incrementais.
- **Linux: falha ao salvar ou ler a sessão**: confirme que há um serviço de secrets ativo (`gnome-keyring-daemon` ou KWallet) e que `libsecret-1-dev` está instalado.
- **macOS: o Keychain pede permissão**: o app usa o Keychain clássico para rodar sem conta de desenvolvedor Apple. Escolha "Permitir sempre".
- **Erro de símbolo ao chamar o Rust após alterar `native/src/api/`**: regenere os bindings com `flutter_rust_bridge_codegen generate` (versão 2.13.0).
