import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

class WatchTimelineUseCase {
  const WatchTimelineUseCase(this._repository);

  final MessageRepository _repository;

  Stream<Result<List<Message>>> call(String roomId) {
    if (roomId.trim().isEmpty) {
      return Stream.value(
        const Err(ValidationFailure(ValidationError.emptyRoomId)),
      );
    }
    return _repository.watchTimeline(roomId);
  }
}
