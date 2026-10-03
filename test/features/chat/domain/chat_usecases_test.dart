import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

const roomId = '!room:matrix.org';

ValidationError? validationErrorOf(Result<Object?> result) => switch (result) {
  Err(failure: ValidationFailure(:final reason)) => reason,
  _ => null,
};

void main() {
  late MockMessageRepository repository;

  setUp(() => repository = MockMessageRepository());

  group('SendMessageUseCase', () {
    late SendMessageUseCase useCase;

    setUp(() {
      useCase = SendMessageUseCase(repository);
      when(
        () => repository.sendText(any(), any()),
      ).thenAnswer((_) async => const Ok<void>(null));
    });

    test('envia o texto sem espaços nas pontas', () async {
      final result = await useCase(roomId, '  olá!\n');

      expect(result, isA<Ok<void>>());
      verify(() => repository.sendText(roomId, 'olá!')).called(1);
    });

    test('rejeita mensagem vazia ou só com espaços', () async {
      expect(
        validationErrorOf(await useCase(roomId, ' \n\t ')),
        ValidationError.emptyMessage,
      );
      verifyNever(() => repository.sendText(any(), any()));
    });

    test('rejeita mensagem acima do limite em bytes', () async {
      // 'é' ocupa 2 bytes em UTF-8: o limite é medido em bytes, não em
      // caracteres.
      final body = 'é' * (SendMessageUseCase.maxBodyBytes ~/ 2 + 1);

      expect(
        validationErrorOf(await useCase(roomId, body)),
        ValidationError.messageTooLong,
      );
    });

    test('aceita mensagem exatamente no limite', () async {
      final body = 'a' * SendMessageUseCase.maxBodyBytes;

      expect(await useCase(roomId, body), isA<Ok<void>>());
    });

    test('rejeita sala vazia', () async {
      expect(
        validationErrorOf(await useCase(' ', 'oi')),
        ValidationError.emptyRoomId,
      );
    });

    test('repassa falha do repositório', () async {
      when(
        () => repository.sendText(any(), any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await useCase(roomId, 'oi');

      expect((result as Err<void>).failure, const NetworkFailure());
    });
  });

  group('WatchTimelineUseCase', () {
    test('delega ao repositório com o ID da sala', () async {
      final messages = [
        Message(
          id: r'$1',
          senderId: '@bob:matrix.org',
          senderName: 'Bob',
          content: const TextContent('oi'),
          timestamp: DateTime(2026, 10, 3),
          isOwn: false,
        ),
      ];
      when(
        () => repository.watchTimeline(roomId),
      ).thenAnswer((_) => Stream.value(Ok(messages)));

      final result = await WatchTimelineUseCase(repository)(roomId).first;

      expect((result as Ok<List<Message>>).value, messages);
    });

    test('emite falha de validação para sala vazia', () async {
      final result = await WatchTimelineUseCase(repository)('').first;

      expect(validationErrorOf(result), ValidationError.emptyRoomId);
      verifyNever(() => repository.watchTimeline(any()));
    });
  });

  group('LoadOlderMessagesUseCase', () {
    test('usa o tamanho de página padrão', () async {
      when(
        () => repository.loadOlderMessages(roomId, count: any(named: 'count')),
      ).thenAnswer((_) async => const Ok(false));

      await LoadOlderMessagesUseCase(repository)(roomId);

      verify(
        () => repository.loadOlderMessages(
          roomId,
          count: LoadOlderMessagesUseCase.defaultPageSize,
        ),
      ).called(1);
    });

    test('informa quando o início da sala foi alcançado', () async {
      when(
        () => repository.loadOlderMessages(roomId, count: 10),
      ).thenAnswer((_) async => const Ok(true));

      final result = await LoadOlderMessagesUseCase(repository)(
        roomId,
        count: 10,
      );

      expect((result as Ok<bool>).value, isTrue);
    });

    test('rejeita sala vazia', () async {
      final result = await LoadOlderMessagesUseCase(repository)(' ');

      expect(validationErrorOf(result), ValidationError.emptyRoomId);
    });
  });

  group('RetryMessageUseCase', () {
    Message message({
      bool isOwn = true,
      MessageSendState sendState = MessageSendState.failed,
    }) => Message(
      id: 'txn1',
      senderId: '@me:matrix.org',
      senderName: 'Eu',
      content: const TextContent('oi'),
      timestamp: DateTime(2026),
      isOwn: isOwn,
      sendState: sendState,
    );

    test('reenvia mensagem própria que falhou pelo ID local', () async {
      when(
        () => repository.retrySend(roomId, 'txn1'),
      ).thenAnswer((_) async => const Ok<void>(null));

      final result = await RetryMessageUseCase(repository)(roomId, message());

      expect(result, isA<Ok<void>>());
      verify(() => repository.retrySend(roomId, 'txn1')).called(1);
    });

    test('rejeita mensagens enviadas ou de outras pessoas', () async {
      final useCase = RetryMessageUseCase(repository);

      final sent = await useCase(
        roomId,
        message(sendState: MessageSendState.sent),
      );
      final other = await useCase(roomId, message(isOwn: false));

      expect(validationErrorOf(sent), ValidationError.messageNotRetryable);
      expect(validationErrorOf(other), ValidationError.messageNotRetryable);
      verifyNever(() => repository.retrySend(any(), any()));
    });
  });

  group('MarkRoomAsReadUseCase', () {
    test('delega ao repositório', () async {
      when(
        () => repository.markAsRead(roomId),
      ).thenAnswer((_) async => const Ok<void>(null));

      await MarkRoomAsReadUseCase(repository)(roomId);

      verify(() => repository.markAsRead(roomId)).called(1);
    });

    test('rejeita sala vazia', () async {
      final result = await MarkRoomAsReadUseCase(repository)('');

      expect(validationErrorOf(result), ValidationError.emptyRoomId);
    });
  });
}
