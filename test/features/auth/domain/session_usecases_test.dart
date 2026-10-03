import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('RestoreSessionUseCase', () {
    test('retorna a sessão restaurada', () async {
      final session = Session(
        userId: '@alice:matrix.org',
        deviceId: 'DEVICE',
        homeserver: Uri.parse('https://matrix.org'),
      );
      when(
        () => repository.restoreSession(),
      ).thenAnswer((_) async => Ok(session));

      final result = await RestoreSessionUseCase(repository)();

      expect((result as Ok<Session>).value, session);
    });

    test('repassa a ausência de sessão', () async {
      when(
        () => repository.restoreSession(),
      ).thenAnswer((_) async => const Err(NoSessionFailure()));

      final result = await RestoreSessionUseCase(repository)();

      expect((result as Err<Session>).failure, const NoSessionFailure());
    });
  });

  group('LogoutUseCase', () {
    test('delega o logout ao repositório', () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Ok<void>(null));

      final result = await LogoutUseCase(repository)();

      expect(result, isA<Ok<void>>());
      verify(() => repository.logout()).called(1);
    });
  });

  group('LoginCredentials', () {
    test('não expõe a senha em toString', () {
      final credentials = LoginCredentials(
        homeserver: Uri.parse('https://matrix.org'),
        username: 'alice',
        password: 'super-secreta',
      );

      expect(credentials.toString(), isNot(contains('super-secreta')));
    });
  });
}
