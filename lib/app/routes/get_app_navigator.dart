import 'package:get/get.dart';
import 'package:matrix_desktop/app/routes/app_routes.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';

/// [AppNavigator] sobre as rotas nomeadas do GetX. Cada fluxo limpa a pilha:
/// não faz sentido "voltar" do login para a home, nem o contrário.
final class GetAppNavigator implements AppNavigator {
  const GetAppNavigator();

  @override
  void toLogin() => Get.offAllNamed<void>(AppRoutes.login);

  @override
  void toHome() => Get.offAllNamed<void>(AppRoutes.home);
}
