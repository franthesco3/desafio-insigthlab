import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/features/auth/data/datasources/session_storage.dart';
import 'package:matrix_desktop/features/auth/data/models/stored_session.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';

void main() {
  late MockFlutterSecureStorage secureStorage;
  late SecureSessionStorage storage;

  setUp(() {
    secureStorage = MockFlutterSecureStorage();
    storage = SecureSessionStorage(secureStorage, random: Random(42));
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => secureStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
  });

  void stubRead(String key, String? value) {
    when(() => secureStorage.read(key: key)).thenAnswer((_) async => value);
  }

  group('sessão', () {
    test('grava e lê a sessão em JSON', () async {
      await storage.writeSession(testStoredSession);
      final written =
          verify(
                () => secureStorage.write(
                  key: SecureSessionStorage.sessionKey,
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      stubRead(SecureSessionStorage.sessionKey, written);

      final session = await storage.readSession();

      expect(session?.toJson(), testStoredSession.toJson());
    });

    test('retorna null quando não há sessão', () async {
      stubRead(SecureSessionStorage.sessionKey, null);

      expect(await storage.readSession(), isNull);
    });

    test('descarta conteúdo corrompido', () async {
      stubRead(SecureSessionStorage.sessionKey, '{not json');

      expect(await storage.readSession(), isNull);
      verify(
        () => secureStorage.delete(key: SecureSessionStorage.sessionKey),
      ).called(1);
    });
  });

  group('passphrase do banco local', () {
    test('gera 32 bytes aleatórios e salva no primeiro uso', () async {
      stubRead(SecureSessionStorage.passphraseKey, null);

      final passphrase = await storage.readOrCreateStorePassphrase();

      expect(base64Url.decode(passphrase), hasLength(32));
      verify(
        () => secureStorage.write(
          key: SecureSessionStorage.passphraseKey,
          value: passphrase,
        ),
      ).called(1);
    });

    test('reaproveita a passphrase existente', () async {
      stubRead(SecureSessionStorage.passphraseKey, 'existente');

      expect(await storage.readOrCreateStorePassphrase(), 'existente');
      verifyNever(
        () => secureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });

  test('clear apaga sessão e passphrase', () async {
    await storage.clear();

    verify(
      () => secureStorage.delete(key: SecureSessionStorage.sessionKey),
    ).called(1);
    verify(
      () => secureStorage.delete(key: SecureSessionStorage.passphraseKey),
    ).called(1);
  });

  test('StoredSession não expõe tokens em toString', () {
    final text = testStoredSession.toString();

    expect(text, isNot(contains('secret')));
    expect(
      StoredSession.fromJson(testStoredSession.toJson()).toString(),
      text,
    );
  });
}
