import 'package:matrix_desktop/core/errors/failure.dart';

/// Tipos de erro que a camada Rust pode reportar.
///
/// Espelha o `MatrixErrorKind` gerado pelo FRB, para que repositórios não
/// dependam do código gerado.
enum NativeErrorKind {
  network,
  homeserverUnreachable,
  invalidCredentials,
  sessionExpired,
  notLoggedIn,
  roomNotFound,
  storage,
  unknown,
}

final class NativeException implements Exception {
  const NativeException(this.kind, [this.message]);

  final NativeErrorKind kind;

  /// Detalhe técnico vindo do Rust. Nunca contém tokens ou senhas.
  final String? message;

  Failure toFailure() => switch (kind) {
    NativeErrorKind.network => NetworkFailure(message),
    NativeErrorKind.homeserverUnreachable => HomeserverUnreachableFailure(
      message,
    ),
    NativeErrorKind.invalidCredentials => InvalidCredentialsFailure(message),
    NativeErrorKind.sessionExpired ||
    NativeErrorKind.notLoggedIn => SessionExpiredFailure(message),
    NativeErrorKind.roomNotFound => RoomNotFoundFailure(message),
    NativeErrorKind.storage || NativeErrorKind.unknown => UnexpectedFailure(
      message,
    ),
  };

  @override
  String toString() => 'NativeException($kind: $message)';
}
