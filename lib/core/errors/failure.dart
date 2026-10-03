import 'package:equatable/equatable.dart';

/// Falhas conhecidas pelo domínio.
///
/// Não carregam texto para o usuário: a tradução para mensagens é
/// responsabilidade da apresentação. [details] guarda informação técnica
/// para logs e nunca deve conter dados sensíveis.
sealed class Failure extends Equatable {
  const Failure([this.details]);

  final String? details;

  @override
  List<Object?> get props => [details];
}

/// Sem conexão ou tempo de resposta esgotado.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.details]);
}

/// O endereço informado não responde como um homeserver Matrix.
final class HomeserverUnreachableFailure extends Failure {
  const HomeserverUnreachableFailure([super.details]);
}

/// Usuário ou senha incorretos.
final class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.details]);
}

/// Não existe sessão salva para restaurar.
final class NoSessionFailure extends Failure {
  const NoSessionFailure([super.details]);
}

/// A sessão salva foi revogada ou expirou no servidor.
final class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.details]);
}

/// A sala não existe ou o usuário não participa dela.
final class RoomNotFoundFailure extends Failure {
  const RoomNotFoundFailure([super.details]);
}

/// Entrada rejeitada antes de chegar à camada de dados.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.reason, [super.details]);

  final ValidationError reason;

  @override
  List<Object?> get props => [reason, details];
}

/// Erro não previsto; deve ser registrado em log.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.details]);
}

enum ValidationError {
  emptyHomeserver,
  invalidHomeserver,
  insecureHomeserver,
  emptyUsername,
  emptyPassword,
  emptyRoomId,
  emptyMessage,
  messageTooLong,
  messageNotRetryable,
}
