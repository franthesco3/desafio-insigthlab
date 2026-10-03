# ADR 002 — GetX restrito à apresentação e ao composition root

**Status:** aceito

## Contexto

O GetX é exigido para gerência de estado. Ele também oferece DI global (`Get.find`), navegação e diálogos sem `BuildContext` — recursos convenientes que, usados em qualquer lugar, acoplam todo o código ao framework e tornam dependências implícitas.

## Decisão

- Usar `GetxController` (ViewModels), `Rx`/`Obx` (reatividade), `Bindings` (DI por rota), `GetPage`/`GetMiddleware` (rotas e `AuthGuard`) e `GetxService` (`SessionService`).
- **Domínio e dados não importam `package:get`.**
- `Get.put`/`Get.lazyPut`/`Get.find` só nos `Bindings` e na definição de rotas. ViewModels recebem dependências **pelo construtor**.
- Views resolvem o ViewModel via `GetView<VM>`; widgets com estado local (formulário, rolagem) são `StatefulWidget` que recebem o ViewModel por parâmetro.
- Navegação passa pela interface `AppNavigator`, injetada nos ViewModels (implementação `GetAppNavigator`).
- Erros são exibidos **inline** a partir do estado do ViewModel (ex.: `sendFailure`, `ViewState.Failed`), sem `Get.snackbar`/`Get.dialog` dentro de ViewModels. Por isso o serviço `UserFeedback`, previsto no início, não foi necessário.

## Consequências

- ViewModels são testados instanciando-os diretamente com mocks, sem container nem rotas reais.
- Trocar o GetX por outro gerenciador afeta só `presentation/` e `Bindings`.
- Abrimos mão de alguns atalhos do GetX (snackbars globais, `Get.find` em qualquer lugar), o que exige um pouco mais de código de ligação.
