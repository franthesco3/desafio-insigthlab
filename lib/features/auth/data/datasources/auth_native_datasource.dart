import 'package:matrix_desktop/core/native/bridge/api/auth.dart' as native;
import 'package:matrix_desktop/core/native/native_call.dart';
import 'package:matrix_desktop/features/auth/data/models/stored_session.dart';

/// Operações de autenticação implementadas em Rust.
///
/// Lança `NativeException` em caso de erro.
abstract interface class AuthNativeDataSource {
  Future<StoredSession> login({
    required Uri homeserver,
    required String username,
    required String password,
    required String storePath,
    required String passphrase,
  });

  Future<void> restoreSession(
    StoredSession session, {
    required String storePath,
    required String passphrase,
  });

  Future<void> logout({required String storePath});
}

final class FrbAuthNativeDataSource implements AuthNativeDataSource {
  const FrbAuthNativeDataSource();

  @override
  Future<StoredSession> login({
    required Uri homeserver,
    required String username,
    required String password,
    required String storePath,
    required String passphrase,
  }) => guardNative(() async {
    final dto = await native.login(
      homeserver: homeserver.toString(),
      username: username,
      password: password,
      storePath: storePath,
      passphrase: passphrase,
    );
    return StoredSession(
      userId: dto.userId,
      deviceId: dto.deviceId,
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      homeserverUrl: dto.homeserverUrl,
    );
  });

  @override
  Future<void> restoreSession(
    StoredSession session, {
    required String storePath,
    required String passphrase,
  }) => guardNative(
    () => native.restoreSession(
      session: native.SessionDto(
        userId: session.userId,
        deviceId: session.deviceId,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        homeserverUrl: session.homeserverUrl,
      ),
      storePath: storePath,
      passphrase: passphrase,
    ),
  );

  @override
  Future<void> logout({required String storePath}) =>
      guardNative(() => native.logout(storePath: storePath));
}
