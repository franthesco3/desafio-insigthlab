import 'dart:convert';

import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';

class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessageRepository _repository;

  /// O Matrix limita um evento a 65.535 bytes. A margem cobre o envelope
  /// JSON (tipo, IDs, timestamps) que o servidor adiciona ao corpo.
  static const maxBodyBytes = 60000;

  Future<Result<void>> call(String roomId, String body) async {
    if (roomId.trim().isEmpty) {
      return const Err(ValidationFailure(ValidationError.emptyRoomId));
    }

    final text = body.trim();
    if (text.isEmpty) {
      return const Err(ValidationFailure(ValidationError.emptyMessage));
    }
    if (utf8.encode(text).length > maxBodyBytes) {
      return const Err(ValidationFailure(ValidationError.messageTooLong));
    }

    return _repository.sendText(roomId, text);
  }
}
