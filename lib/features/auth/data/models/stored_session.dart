import 'package:matrix_desktop/features/auth/domain/entities/session.dart';

/// Sessão completa, com tokens, como persistida no cofre do SO.
///
/// Existe apenas na camada de dados; a apresentação recebe [Session].
final class StoredSession {
  const StoredSession({
    required this.userId,
    required this.deviceId,
    required this.accessToken,
    required this.homeserverUrl,
    this.refreshToken,
  });

  factory StoredSession.fromJson(Map<String, dynamic> json) => StoredSession(
    userId: json['userId'] as String,
    deviceId: json['deviceId'] as String,
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    homeserverUrl: json['homeserverUrl'] as String,
  );

  final String userId;
  final String deviceId;
  final String accessToken;
  final String? refreshToken;
  final String homeserverUrl;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'deviceId': deviceId,
    'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    'homeserverUrl': homeserverUrl,
  };

  Session toSession() => Session(
    userId: userId,
    deviceId: deviceId,
    homeserver: Uri.parse(homeserverUrl),
  );

  // Nunca expor tokens em logs.
  @override
  String toString() => 'StoredSession($userId, $deviceId @ $homeserverUrl)';
}
