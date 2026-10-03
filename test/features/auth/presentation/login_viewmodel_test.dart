import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';

void main() {
  late MockLoginUseCase login;
  late MockAppNavigator navigator;
  late SessionService sessionService;
  late LoginViewModel viewModel;

  setUpAll(() {
    Get.testMode = true;
    registerFallbackValue((homeserver: '', username: '', password: ''));
  });

  setUp(() {
    login = MockLoginUseCase();
    navigator = MockAppNavigator();
    sessionService = SessionService();
    viewModel = LoginViewModel(
      login: login,
      sessionService: sessionService,
      navigator: navigator,
    );
  });

  Future<void> submit() => viewModel.submit(
    homeserver: 'matrix.org',
    username: 'alice',
    password: 'secret',
  );

  test('em caso de sucesso inicia a sessão e vai para a home', () async {
    when(() => login(any())).thenAnswer((_) async => Ok(testSession));

    await submit();

    expect(sessionService.current.value, testSession);
    verify(navigator.toHome).called(1);
    verify(
      () => login((
        homeserver: 'matrix.org',
        username: 'alice',
        password: 'secret',
      )),
    ).called(1);
  });

  test('em caso de falha exibe a mensagem e não navega', () async {
    when(
      () => login(any()),
    ).thenAnswer((_) async => const Err(InvalidCredentialsFailure()));

    await submit();

    expect(viewModel.state.value, isA<Failed<void>>());
    expect(viewModel.errorMessage, 'Usuário ou senha incorretos.');
    expect(sessionService.isAuthenticated, isFalse);
    verifyNever(navigator.toHome);
  });

  test('fica em Loading durante a requisição e ignora reenvio', () async {
    when(() => login(any())).thenAnswer((_) async {
      expect(viewModel.isLoading, isTrue);
      await viewModel.submit(homeserver: 'x', username: 'y', password: 'z');
      return Ok(testSession);
    });

    await submit();

    verify(() => login(any())).called(1);
  });

  test('clearError volta ao estado inicial após uma falha', () async {
    when(
      () => login(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    await submit();

    viewModel.clearError();

    expect(viewModel.state.value, isA<Idle<void>>());
    expect(viewModel.errorMessage, isNull);
  });
}
