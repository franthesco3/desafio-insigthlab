import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';
import 'package:matrix_desktop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';

void main() {
  setUpAll(() => Get.testMode = true);

  test('logout encerra a sessão local e volta ao login', () async {
    final logout = MockLogoutUseCase();
    final navigator = MockAppNavigator();
    final sessionService = SessionService()..start(testSession);
    final viewModel = HomeViewModel(
      logout: logout,
      sessionService: sessionService,
      navigator: navigator,
    );
    when(logout.call).thenAnswer((_) async => const Ok<void>(null));

    expect(viewModel.userId, testSession.userId);
    await viewModel.logout();

    verify(logout.call).called(1);
    expect(sessionService.isAuthenticated, isFalse);
    expect(viewModel.isLoggingOut.value, isFalse);
    verify(navigator.toLogin).called(1);
  });
}
