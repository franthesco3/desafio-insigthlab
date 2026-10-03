import 'package:matrix_desktop/core/native/bridge/api/timeline.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';

extension MessageDtoMapper on MessageDto {
  Message toEntity() => Message(
    id: id,
    senderId: senderId,
    senderName: senderName,
    content: _content,
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    isOwn: isOwn,
    sendState: switch (sendState) {
      SendStateDto.sending => MessageSendState.sending,
      SendStateDto.sent => MessageSendState.sent,
      SendStateDto.failed => MessageSendState.failed,
    },
  );

  MessageContent get _content => switch (kind) {
    MessageKindDto.text => TextContent(body ?? ''),
    MessageKindDto.redacted => const RedactedContent(),
    MessageKindDto.undecryptable => const UndecryptableContent(),
    MessageKindDto.unsupported => UnsupportedContent(eventType ?? 'unknown'),
  };
}
