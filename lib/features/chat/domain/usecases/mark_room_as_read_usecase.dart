import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

class MarkRoomAsReadUseCase {
  const MarkRoomAsReadUseCase(this._repository);

  final MessageRepository _repository;

  Future<Result<void>> call(String roomId) {
    if (roomId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure(ValidationError.emptyRoomId)),
      );
    }
    return _repository.markAsRead(roomId);
  }
}
