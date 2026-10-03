import 'package:get/get.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

/// Tela principal autenticada: conta e logout. Salas e chat têm ViewModels
/// próprios.
class HomeViewModel extends GetxController {
  HomeViewModel({
    required LogoutUseCase logout,
    required SessionService sessionService,
    required AppNavigator navigator,
  }) : _logout = logout,
       _sessionService = sessionService,
       _navigator = navigator;

  final LogoutUseCase _logout;
  final SessionService _sessionService;
  final AppNavigator _navigator;

  final RxBool isLoggingOut = false.obs;

  String get userId => _sessionService.current.value?.userId ?? '';

  /// O logout sempre conclui localmente (ver `AuthRepository.logout`), então
  /// o usuário é levado ao login independentemente do resultado no servidor.
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    await _logout();
    _sessionService.end();
    isLoggingOut.value = false;
    _navigator.toLogin();
  }
}
