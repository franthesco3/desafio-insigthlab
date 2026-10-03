import 'package:equatable/equatable.dart';

/// Mensagem da timeline de uma sala.
final class Message extends Equatable {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isOwn,
    this.sendState = MessageSendState.sent,
  });

  /// Event ID do servidor ou, enquanto não confirmada, o ID local da
  /// transação (local echo).
  final String id;
  final String senderId;
  final String senderName;
  final MessageContent content;
  final DateTime timestamp;

  /// Se foi enviada pelo usuário da sessão atual.
  final bool isOwn;
  final MessageSendState sendState;

  bool get canRetry => isOwn && sendState == MessageSendState.failed;

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderName,
    content,
    timestamp,
    isOwn,
    sendState,
  ];
}

enum MessageSendState { sending, sent, failed }

/// Conteúdo de uma mensagem. Novos tipos (imagem, arquivo...) entram como
/// novas subclasses, sem alterar as existentes.
sealed class MessageContent extends Equatable {
  const MessageContent();
}

final class TextContent extends MessageContent {
  const TextContent(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

/// Mensagem criptografada cujas chaves este dispositivo não possui.
final class UndecryptableContent extends MessageContent {
  const UndecryptableContent();

  @override
  List<Object?> get props => [];
}

/// Mensagem apagada pelo autor ou por um moderador.
final class RedactedContent extends MessageContent {
  const RedactedContent();

  @override
  List<Object?> get props => [];
}

/// Tipo de evento ainda não suportado pelo app (ex.: `m.image`).
final class UnsupportedContent extends MessageContent {
  const UnsupportedContent(this.type);

  final String type;

  @override
  List<Object?> get props => [type];
}
