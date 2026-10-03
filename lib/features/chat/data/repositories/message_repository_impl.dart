import 'package:matrix_desktop/core/native/native_result.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/data/datasources/chat_native_datasource.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

final class MessageRepositoryImpl implements MessageRepository {
  const MessageRepositoryImpl(this._native);

  final ChatNativeDataSource _native;

  /// O Rust aceita no máximo `u16` eventos por página.
  static const _maxPageSize = 0xFFFF;

  @override
  Stream<Result<List<Message>>> watchTimeline(String roomId) =>
      _native.watchTimeline(roomId).asResults();

  @override
  Future<Result<bool>> loadOlderMessages(
    String roomId, {
    required int count,
  }) => _guard(
    () => _native.paginateBackwards(
      roomId,
      count: count.clamp(1, _maxPageSize),
    ),
  );

  @override
  Future<Result<void>> sendText(String roomId, String body) =>
      _guard(() => _native.sendText(roomId, body));

  @override
  Future<Result<void>> retrySend(String roomId, String messageId) =>
      _guard(() => _native.retrySend(roomId, messageId));

  @override
  Future<Result<void>> markAsRead(String roomId) =>
      _guard(() => _native.markAsRead(roomId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) =>
      guardResult(() async => Ok(await action()));
}
