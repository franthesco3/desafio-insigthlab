import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';

abstract interface class MessageRepository {
  /// Emite a timeline completa da sala, da mais antiga para a mais recente,
  /// a cada mudança (nova mensagem, confirmação de envio, paginação).
  Stream<Result<List<Message>>> watchTimeline(String roomId);

  /// Carrega até [count] mensagens anteriores. Retorna `true` quando o
  /// início da sala foi alcançado.
  Future<Result<bool>> loadOlderMessages(String roomId, {required int count});

  /// Enfileira o envio. O progresso (enviando → enviada/falhou) chega pelo
  /// stream de [watchTimeline] (local echo).
  Future<Result<void>> sendText(String roomId, String body);

  /// Reenvia uma mensagem que falhou; [messageId] é o ID local (`Message.id`).
  Future<Result<void>> retrySend(String roomId, String messageId);

  /// Marca a sala como lida até a mensagem mais recente.
  Future<Result<void>> markAsRead(String roomId);
}
