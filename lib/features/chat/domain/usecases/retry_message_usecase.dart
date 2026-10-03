import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

class RetryMessageUseCase {
  const RetryMessageUseCase(this._repository);

  final MessageRepository _repository;

  /// Só mensagens próprias que falharam podem ser reenviadas.
  Future<Result<void>> call(String roomId, Message message) {
    if (roomId.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure(ValidationError.emptyRoomId)),
      );
    }
    if (!message.canRetry) {
      return Future.value(
        const Err(ValidationFailure(ValidationError.messageNotRetryable)),
      );
    }
    return _repository.retrySend(roomId, message.id);
  }
}
