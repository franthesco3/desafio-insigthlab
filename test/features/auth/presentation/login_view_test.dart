import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:matrix_desktop/features/auth/presentation/views/login_view.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';
import '../../../mocks/repository_mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(testStoredSession);
    registerFallbackValue(fallbackCredentials);
  });

  setUp(() {
    repository = MockAuthRepository();
    // Use case real: o teste cobre View + ViewModel + validação do domínio.
    Get.put(
      LoginViewModel(
        login: LoginUseCase(repository),
        sessionService: SessionService(),
        navigator: MockAppNavigator(),
      ),
    );
  });

  tearDown(Get.reset);

  Future<void> pumpLogin(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(home: LoginView()));

  testWidgets('vem com matrix.org como servidor padrão', (tester) async {
    await pumpLogin(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key('login.homeserver')),
    );
    expect(field.controller?.text, 'matrix.org');
  });

  testWidgets('mostra erro de validação sem chamar o servidor', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    expect(find.text('Informe o usuário.'), findsOneWidget);
    verifyNever(() => repository.login(any()));
  });

  testWidgets('mostra erro do servidor e limpa ao editar', (tester) async {
    when(
      () => repository.login(any()),
    ).thenAnswer((_) async => const Err<Session>(InvalidCredentialsFailure()));
    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login.username')), 'alice');
    await tester.enterText(find.byKey(const Key('login.password')), 'errada');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    expect(find.text('Usuário ou senha incorretos.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login.password')), 'outra');
    await tester.pump();

    expect(find.text('Usuário ou senha incorretos.'), findsNothing);
  });

  testWidgets('Enter no campo de senha envia o formulário', (tester) async {
    when(
      () => repository.login(any()),
    ).thenAnswer((_) async => Ok(testSession));
    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('login.username')), 'alice');
    await tester.enterText(find.byKey(const Key('login.password')), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(() => repository.login(any())).called(1);
  });
}
