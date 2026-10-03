import 'package:matrix_desktop/core/errors/failure.dart';

/// Tradução de falhas do domínio em mensagens para o usuário.
extension FailureMessage on Failure {
  String get userMessage => switch (this) {
    NetworkFailure() => 'Sem conexão com a internet. Verifique sua rede.',
    HomeserverUnreachableFailure() =>
      'Não encontramos um servidor Matrix nesse endereço.',
    InvalidCredentialsFailure() => 'Usuário ou senha incorretos.',
    NoSessionFailure() => 'Nenhuma sessão salva.',
    SessionExpiredFailure() => 'Sua sessão expirou. Entre novamente.',
    RoomNotFoundFailure() => 'Sala não encontrada.',
    ValidationFailure(:final reason) => reason.userMessage,
    UnexpectedFailure() => 'Algo deu errado. Tente novamente.',
  };
}

extension on ValidationError {
  String get userMessage => switch (this) {
    ValidationError.emptyHomeserver => 'Informe o servidor.',
    ValidationError.invalidHomeserver => 'Endereço de servidor inválido.',
    ValidationError.insecureHomeserver =>
      'Use um servidor com https:// para proteger sua conta.',
    ValidationError.emptyUsername => 'Informe o usuário.',
    ValidationError.emptyPassword => 'Informe a senha.',
    ValidationError.emptyRoomId => 'Sala inválida.',
    ValidationError.emptyMessage => 'A mensagem está vazia.',
    ValidationError.messageTooLong => 'A mensagem é longa demais.',
    ValidationError.messageNotRetryable =>
      'Esta mensagem não pode ser reenviada.',
  };
}
