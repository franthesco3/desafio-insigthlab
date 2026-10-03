import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matrix_desktop/core/native/bridge/api/health.dart';
import 'package:matrix_desktop/core/native/native_bridge.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/features/auth/data/datasources/auth_native_datasource.dart';
import 'package:matrix_desktop/features/auth/data/models/stored_session.dart';
import 'package:matrix_desktop/features/chat/data/datasources/chat_native_datasource.dart';
import 'package:matrix_desktop/features/rooms/data/datasources/rooms_native_datasource.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(NativeBridge.init);

  test('valida user IDs usando o matrix-sdk via ponte Rust', () {
    expect(nativeInfo().crateVersion, isNotEmpty);
    expect(isValidUserId(userId: '@alice:matrix.org'), isTrue);
    expect(isValidUserId(userId: 'alice'), isFalse);
  });

  test('erros do Rust chegam ao Dart como NativeException tipada', () async {
    const dataSource = FrbAuthNativeDataSource();

    await expectLater(
      dataSource.restoreSession(
        // User ID malformado: o Rust rejeita antes de qualquer acesso à rede.
        const StoredSession(
          userId: 'not-a-user-id',
          deviceId: 'DEVICE',
          accessToken: 'token',
          homeserverUrl: 'https://example.org',
        ),
        storePath: '/tmp/matrix_desktop_bridge_test',
        passphrase: 'x',
      ),
      throwsA(
        isA<NativeException>().having(
          (e) => e.kind,
          'kind',
          NativeErrorKind.sessionExpired,
        ),
      ),
    );
  });

  test('streams do Rust propagam erros tipados (sem sessão ativa)', () async {
    await expectLater(
      const FrbRoomsNativeDataSource().watchRooms(),
      emitsError(
        isA<NativeException>().having(
          (e) => e.kind,
          'kind',
          NativeErrorKind.notLoggedIn,
        ),
      ),
    );
  });

  test('timeline rejeita room ID malformado como sala inexistente', () async {
    await expectLater(
      const FrbChatNativeDataSource().watchTimeline('not-a-room-id'),
      emitsError(
        isA<NativeException>().having(
          (e) => e.kind,
          'kind',
          NativeErrorKind.roomNotFound,
        ),
      ),
    );
  });

  test('envio sem sessão ativa falha com erro tipado', () async {
    await expectLater(
      const FrbChatNativeDataSource().sendText('!room:matrix.org', 'oi'),
      throwsA(
        isA<NativeException>().having(
          (e) => e.kind,
          'kind',
          NativeErrorKind.notLoggedIn,
        ),
      ),
    );
  });
}
