import 'package:matrix_desktop/core/native/bridge/api/timeline.dart' as native;
import 'package:matrix_desktop/core/native/native_call.dart';
import 'package:matrix_desktop/features/chat/data/mappers/message_mapper.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';

/// Timeline e envio de mensagens implementados em Rust. Erros chegam como
/// `NativeException`.
abstract interface class ChatNativeDataSource {
  Stream<List<Message>> watchTimeline(String roomId);

  Future<bool> paginateBackwards(String roomId, {required int count});

  Future<void> sendText(String roomId, String body);

  Future<void> retrySend(String roomId, String transactionId);

  Future<void> markAsRead(String roomId);
}

final class FrbChatNativeDataSource implements ChatNativeDataSource {
  const FrbChatNativeDataSource();

  @override
  Stream<List<Message>> watchTimeline(String roomId) => guardNativeStream(
    native.watchTimeline(roomId: roomId),
  ).map((messages) => [for (final message in messages) message.toEntity()]);

  @override
  Future<bool> paginateBackwards(String roomId, {required int count}) =>
      guardNative(() => native.paginateBackwards(roomId: roomId, count: count));

  @override
  Future<void> sendText(String roomId, String body) =>
      guardNative(() => native.sendText(roomId: roomId, body: body));

  @override
  Future<void> retrySend(String roomId, String transactionId) => guardNative(
    () => native.retrySend(roomId: roomId, transactionId: transactionId),
  );

  @override
  Future<void> markAsRead(String roomId) =>
      guardNative(() => native.markAsRead(roomId: roomId));
}
