import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/native/native_result.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/storage/app_directories.dart';
import 'package:matrix_desktop/features/auth/data/datasources/auth_native_datasource.dart';
import 'package:matrix_desktop/features/auth/data/datasources/session_storage.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthNativeDataSource native,
    required SessionStorage storage,
    required AppDirectories directories,
  }) : _native = native,
       _storage = storage,
       _directories = directories;

  final AuthNativeDataSource _native;
  final SessionStorage _storage;
  final AppDirectories _directories;

  @override
  Future<Result<Session>> login(LoginCredentials credentials) {
    return guardResult(() async {
      final stored = await _native.login(
        homeserver: credentials.homeserver,
        username: credentials.username,
        password: credentials.password,
        storePath: await _directories.matrixStorePath(),
        passphrase: await _storage.readOrCreateStorePassphrase(),
      );
      await _storage.writeSession(stored);
      return Ok(stored.toSession());
    });
  }

  @override
  Future<Result<Session>> restoreSession() {
    return guardResult(() async {
      final stored = await _storage.readSession();
      if (stored == null) return const Err(NoSessionFailure());

      try {
        await _native.restoreSession(
          stored,
          storePath: await _directories.matrixStorePath(),
          passphrase: await _storage.readOrCreateStorePassphrase(),
        );
      } on NativeException catch (error) {
        if (error.kind == NativeErrorKind.sessionExpired) {
          await _storage.clear();
        }
        rethrow;
      }
      return Ok(stored.toSession());
    });
  }

  @override
  Future<Result<void>> logout() {
    return guardResult(() async {
      try {
        await _native.logout(storePath: await _directories.matrixStorePath());
      } on NativeException {
        // O Rust já apaga o banco local mesmo sem resposta do servidor; o
        // logout local nunca deve ser bloqueado.
      } finally {
        await _storage.clear();
      }
      return const Ok<void>(null);
    });
  }
}
