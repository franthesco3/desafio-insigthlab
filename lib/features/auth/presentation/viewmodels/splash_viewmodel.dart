import 'dart:async';

import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

/// Decide para onde ir ao abrir o app, restaurando a sessão salva.
class SplashViewModel extends GetxController {
  SplashViewModel({
    required RestoreSessionUseCase restoreSession,
    required SessionService sessionService,
    required AppNavigator navigator,
  }) : _restoreSession = restoreSession,
       _sessionService = sessionService,
       _navigator = navigator;

  final RestoreSessionUseCase _restoreSession;
  final SessionService _sessionService;
  final AppNavigator _navigator;

  final state = Rx<ViewState<void>>(const Idle());

  @override
  void onReady() {
    super.onReady();
    unawaited(restore());
  }

  Future<void> restore() async {
    state.value = const Loading();
    switch (await _restoreSession()) {
      case Ok(:final value):
        _sessionService.start(value);
        _navigator.toHome();
      case Err(failure: NoSessionFailure() || SessionExpiredFailure()):
        _navigator.toLogin();
      case Err(:final failure):
        state.value = Failed(failure);
    }
  }

  void goToLogin() => _navigator.toLogin();
}
