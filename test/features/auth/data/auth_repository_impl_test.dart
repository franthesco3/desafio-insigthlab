import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';

void main() {
  const storePath = '/support/matrix_store';
  const passphrase = 'passphrase';

  late MockAuthNativeDataSource native;
  late MockSessionStorage storage;
  late AuthRepositoryImpl repository;

  final credentials = LoginCredentials(
    homeserver: Uri.parse('https://matrix.org'),
    username: 'alice',
    password: 'secret',
  );

  setUpAll(() {
    registerFallbackValue(testStoredSession);
    registerFallbackValue(Uri());
  });

  setUp(() {
    native = MockAuthNativeDataSource();
    storage = MockSessionStorage();
    final directories = MockAppDirectories();
    repository = AuthRepositoryImpl(
      native: native,
      storage: storage,
      directories: directories,
    );

    when(directories.matrixStorePath).thenAnswer((_) async => storePath);
    when(
      storage.readOrCreateStorePassphrase,
    ).thenAnswer((_) async => passphrase);
    when(() => storage.writeSession(any())).thenAnswer((_) async {});
    when(storage.clear).thenAnswer((_) async {});
  });

  group('login', () {
    void stubNativeLogin() {
      when(
        () => native.login(
          homeserver: any(named: 'homeserver'),
          username: any(named: 'username'),
          password: any(named: 'password'),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      ).thenAnswer((_) async => testStoredSession);
    }

    test('autentica com a passphrase do cofre e persiste a sessão', () async {
      stubNativeLogin();

      final result = await repository.login(credentials);

      expect((result as Ok<Session>).value, testSession);
      verify(
        () => native.login(
          homeserver: credentials.homeserver,
          username: 'alice',
          password: 'secret',
          storePath: storePath,
          passphrase: passphrase,
        ),
      ).called(1);
      verify(() => storage.writeSession(testStoredSession)).called(1);
    });

    test('converte erro nativo em Failure e não persiste nada', () async {
      when(
        () => native.login(
          homeserver: any(named: 'homeserver'),
          username: any(named: 'username'),
          password: any(named: 'password'),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      ).thenThrow(const NativeException(NativeErrorKind.invalidCredentials));

      final result = await repository.login(credentials);

      expect((result as Err).failure, isA<InvalidCredentialsFailure>());
      verifyNever(() => storage.writeSession(any()));
    });

    test('converte erro inesperado em UnexpectedFailure', () async {
      when(storage.readOrCreateStorePassphrase).thenThrow(Exception('cofre'));

      final result = await repository.login(credentials);

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });

  group('restoreSession', () {
    void stubNativeRestore() {
      when(
        () => native.restoreSession(
          any(),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      ).thenAnswer((_) async {});
    }

    test('falha com NoSessionFailure quando não há sessão salva', () async {
      when(storage.readSession).thenAnswer((_) async => null);

      final result = await repository.restoreSession();

      expect((result as Err).failure, isA<NoSessionFailure>());
      verifyNever(
        () => native.restoreSession(
          any(),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      );
    });

    test('restaura a sessão salva no Rust', () async {
      when(storage.readSession).thenAnswer((_) async => testStoredSession);
      stubNativeRestore();

      final result = await repository.restoreSession();

      expect((result as Ok<Session>).value, testSession);
      verify(
        () => native.restoreSession(
          testStoredSession,
          storePath: storePath,
          passphrase: passphrase,
        ),
      ).called(1);
    });

    test('apaga a sessão salva quando o token expirou', () async {
      when(storage.readSession).thenAnswer((_) async => testStoredSession);
      when(
        () => native.restoreSession(
          any(),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      ).thenThrow(const NativeException(NativeErrorKind.sessionExpired));

      final result = await repository.restoreSession();

      expect((result as Err).failure, isA<SessionExpiredFailure>());
      verify(storage.clear).called(1);
    });

    test('mantém a sessão salva em outras falhas', () async {
      when(storage.readSession).thenAnswer((_) async => testStoredSession);
      when(
        () => native.restoreSession(
          any(),
          storePath: any(named: 'storePath'),
          passphrase: any(named: 'passphrase'),
        ),
      ).thenThrow(const NativeException(NativeErrorKind.storage));

      final result = await repository.restoreSession();

      expect((result as Err).failure, isA<UnexpectedFailure>());
      verifyNever(storage.clear);
    });
  });

  group('logout', () {
    test('encerra no Rust e limpa o cofre', () async {
      when(
        () => native.logout(storePath: any(named: 'storePath')),
      ).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result, isA<Ok<void>>());
      verify(() => native.logout(storePath: storePath)).called(1);
      verify(storage.clear).called(1);
    });

    test('limpa o cofre mesmo quando o Rust falha', () async {
      when(
        () => native.logout(storePath: any(named: 'storePath')),
      ).thenThrow(const NativeException(NativeErrorKind.network));

      final result = await repository.logout();

      expect(result, isA<Ok<void>>());
      verify(storage.clear).called(1);
    });
  });
}
