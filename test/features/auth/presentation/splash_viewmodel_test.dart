import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/splash_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';

void main() {
  late MockRestoreSessionUseCase restoreSession;
  late MockAppNavigator navigator;
  late SessionService sessionService;
  late SplashViewModel viewModel;

  setUpAll(() => Get.testMode = true);

  setUp(() {
    restoreSession = MockRestoreSessionUseCase();
    navigator = MockAppNavigator();
    sessionService = SessionService();
    viewModel = SplashViewModel(
      restoreSession: restoreSession,
      sessionService: sessionService,
      navigator: navigator,
    );
  });

  test('sessão restaurada: inicia a sessão e vai para a home', () async {
    when(restoreSession.call).thenAnswer((_) async => Ok(testSession));

    await viewModel.restore();

    expect(sessionService.current.value, testSession);
    verify(navigator.toHome).called(1);
  });

  for (final failure in [
    const NoSessionFailure(),
    const SessionExpiredFailure(),
  ]) {
    test('${failure.runtimeType}: vai para o login', () async {
      when(restoreSession.call).thenAnswer((_) async => Err(failure));

      await viewModel.restore();

      verify(navigator.toLogin).called(1);
      verifyNever(navigator.toHome);
    });
  }

  test('outras falhas: exibe erro e permite tentar de novo', () async {
    when(
      restoreSession.call,
    ).thenAnswer((_) async => const Err(UnexpectedFailure()));

    await viewModel.restore();

    expect(viewModel.state.value, isA<Failed<void>>());
    verifyNever(navigator.toLogin);
    verifyNever(navigator.toHome);
  });
}
