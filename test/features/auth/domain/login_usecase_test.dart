import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  final session = Session(
    userId: '@alice:matrix.org',
    deviceId: 'DEVICE',
    homeserver: Uri.parse('https://matrix.org'),
  );

  LoginParams params({
    String homeserver = 'matrix.org',
    String username = 'alice',
    String password = 'secret',
  }) => (homeserver: homeserver, username: username, password: password);

  setUpAll(() {
    registerFallbackValue(
      LoginCredentials(homeserver: Uri(), username: '', password: ''),
    );
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
    when(() => repository.login(any())).thenAnswer((_) async => Ok(session));
  });

  Future<ValidationError?> validationErrorFor(LoginParams input) async {
    final result = await useCase(input);
    return switch (result) {
      Err(failure: ValidationFailure(:final reason)) => reason,
      _ => null,
    };
  }

  group('validação', () {
    test('rejeita homeserver vazio', () async {
      expect(
        await validationErrorFor(params(homeserver: '  ')),
        ValidationError.emptyHomeserver,
      );
    });

    test('rejeita homeserver malformado', () async {
      expect(
        await validationErrorFor(params(homeserver: 'matrix org')),
        ValidationError.invalidHomeserver,
      );
      expect(
        await validationErrorFor(params(homeserver: 'ftp://matrix.org')),
        ValidationError.invalidHomeserver,
      );
    });

    test('rejeita http em servidor remoto', () async {
      expect(
        await validationErrorFor(params(homeserver: 'http://matrix.org')),
        ValidationError.insecureHomeserver,
      );
    });

    test('rejeita usuário vazio', () async {
      expect(
        await validationErrorFor(params(username: ' ')),
        ValidationError.emptyUsername,
      );
    });

    test('rejeita senha vazia', () async {
      expect(
        await validationErrorFor(params(password: '')),
        ValidationError.emptyPassword,
      );
    });

    test('não chama o repositório quando a entrada é inválida', () async {
      await useCase(params(password: ''));

      verifyNever(() => repository.login(any()));
    });
  });

  group('normalização', () {
    Future<LoginCredentials> credentialsSentFor(LoginParams input) async {
      await useCase(input);
      return verify(() => repository.login(captureAny())).captured.single
          as LoginCredentials;
    }

    test('assume https quando o esquema é omitido', () async {
      final credentials = await credentialsSentFor(params());

      expect(credentials.homeserver, Uri.parse('https://matrix.org'));
    });

    test('aceita http apenas para servidor local', () async {
      final credentials = await credentialsSentFor(
        params(homeserver: 'http://localhost:8008'),
      );

      expect(credentials.homeserver, Uri.parse('http://localhost:8008'));
    });

    test('remove espaços do usuário mas preserva a senha', () async {
      final credentials = await credentialsSentFor(
        params(username: '  @alice:matrix.org ', password: ' s3nha '),
      );

      expect(credentials.username, '@alice:matrix.org');
      expect(credentials.password, ' s3nha ');
    });
  });

  test('retorna a sessão quando o repositório autentica', () async {
    final result = await useCase(params());

    expect(result, isA<Ok<Session>>());
    expect((result as Ok<Session>).value, session);
  });

  test('repassa a falha do repositório', () async {
    when(
      () => repository.login(any()),
    ).thenAnswer((_) async => const Err(InvalidCredentialsFailure()));

    final result = await useCase(params());

    expect((result as Err<Session>).failure, const InvalidCredentialsFailure());
  });
}
