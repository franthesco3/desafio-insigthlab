import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix_desktop/features/auth/data/models/stored_session.dart';

/// Persistência da sessão e da passphrase do banco local.
abstract interface class SessionStorage {
  Future<StoredSession?> readSession();

  Future<void> writeSession(StoredSession session);

  /// Passphrase que criptografa o banco SQLite do matrix-sdk. É gerada no
  /// primeiro uso e reaproveitada até o logout.
  Future<String> readOrCreateStorePassphrase();

  /// Apaga sessão e passphrase.
  Future<void> clear();
}

/// [SessionStorage] sobre o cofre do SO: Keychain (macOS), Credential
/// Manager (Windows) e libsecret (Linux).
final class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  final FlutterSecureStorage _storage;
  final Random _random;

  static const sessionKey = 'matrix_session';
  static const passphraseKey = 'matrix_store_passphrase';
  static const _passphraseBytes = 32;

  @override
  Future<StoredSession?> readSession() async {
    final raw = await _storage.read(key: sessionKey);
    if (raw == null) return null;
    try {
      return StoredSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Conteúdo corrompido ou de versão incompatível: tratar como ausente.
      await _storage.delete(key: sessionKey);
      return null;
    }
  }

  @override
  Future<void> writeSession(StoredSession session) =>
      _storage.write(key: sessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<String> readOrCreateStorePassphrase() async {
    final existing = await _storage.read(key: passphraseKey);
    if (existing != null) return existing;

    final bytes = List<int>.generate(
      _passphraseBytes,
      (_) => _random.nextInt(256),
    );
    final passphrase = base64UrlEncode(bytes);
    await _storage.write(key: passphraseKey, value: passphrase);
    return passphrase;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: sessionKey);
    await _storage.delete(key: passphraseKey);
  }
}
