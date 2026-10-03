import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

class LoadOlderMessagesUseCase {
  const LoadOlderMessagesUseCase(this._repository);

  final MessageRepository _repository;

  static const defaultPageSize = 30;

  /// Retorna `true` quando não há mais mensagens anteriores.
  Future<Result<bool>> call(String roomId, {int count = defaultPageSize}) {
    if (roomId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure(ValidationError.emptyRoomId)),
      );
    }
    return _repository.loadOlderMessages(roomId, count: count);
  }
}
