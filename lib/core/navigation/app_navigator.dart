/// Navegação entre os fluxos principais, sem depender de `BuildContext`.
///
/// ViewModels recebem esta abstração para continuarem testáveis.
abstract interface class AppNavigator {
  void toLogin();

  void toHome();
}
