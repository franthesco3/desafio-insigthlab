import 'package:get/get.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/failure_messages.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

class LoginViewModel extends GetxController {
  LoginViewModel({
    required LoginUseCase login,
    required SessionService sessionService,
    required AppNavigator navigator,
  }) : _login = login,
       _sessionService = sessionService,
       _navigator = navigator;

  final LoginUseCase _login;
  final SessionService _sessionService;
  final AppNavigator _navigator;

  static const defaultHomeserver = 'matrix.org';

  final state = Rx<ViewState<void>>(const Idle());

  bool get isLoading => state.value is Loading;

  String? get errorMessage => switch (state.value) {
    Failed(:final failure) => failure.userMessage,
    _ => null,
  };

  Future<void> submit({
    required String homeserver,
    required String username,
    required String password,
  }) async {
    if (isLoading) return;
    state.value = const Loading();

    final result = await _login((
      homeserver: homeserver,
      username: username,
      password: password,
    ));
    switch (result) {
      case Ok(:final value):
        state.value = const Success(null);
        _sessionService.start(value);
        _navigator.toHome();
      case Err(:final failure):
        state.value = Failed(failure);
    }
  }

  /// Remove a mensagem de erro quando o usuário volta a editar o formulário.
  void clearError() {
    if (state.value is Failed) state.value = const Idle();
  }
}
