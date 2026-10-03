import 'package:equatable/equatable.dart';

/// Sessão autenticada exposta ao restante do app.
///
/// O access token fica de fora de propósito: ele vive apenas na camada de
/// dados (cofre do SO e Rust), nunca na apresentação.
final class Session extends Equatable {
  const Session({
    required this.userId,
    required this.deviceId,
    required this.homeserver,
  });

  /// Matrix user ID completo, ex.: `@alice:matrix.org`.
  final String userId;
  final String deviceId;
  final Uri homeserver;

  @override
  List<Object?> get props => [userId, deviceId, homeserver];
}
