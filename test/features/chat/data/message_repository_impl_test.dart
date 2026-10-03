import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/bridge/api/timeline.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/data/datasources/chat_native_datasource.dart';
import 'package:matrix_desktop/features/chat/data/mappers/message_mapper.dart';
import 'package:matrix_desktop/features/chat/data/repositories/message_repository_impl.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:mocktail/mocktail.dart';

class MockChatNativeDataSource extends Mock implements ChatNativeDataSource {}

const roomId = '!room:matrix.org';

MessageDto dto({
  MessageKindDto kind = MessageKindDto.text,
  String? body = 'olá',
  String? eventType,
  SendStateDto sendState = SendStateDto.sent,
}) => MessageDto(
  id: r'$1',
  senderId: '@alice:matrix.org',
  senderName: 'Alice',
  kind: kind,
  body: body,
  eventType: eventType,
  timestampMs: DateTime(2026, 10, 3, 12).millisecondsSinceEpoch,
  isOwn: false,
  sendState: sendState,
);

void main() {
  group('MessageDtoMapper', () {
    test('converte mensagem de texto', () {
      expect(
        dto().toEntity(),
        Message(
          id: r'$1',
          senderId: '@alice:matrix.org',
          senderName: 'Alice',
          content: const TextContent('olá'),
          timestamp: DateTime(2026, 10, 3, 12),
          isOwn: false,
        ),
      );
    });

    test('converte os demais tipos de conteúdo', () {
      MessageContent contentOf(MessageDto value) => value.toEntity().content;

      expect(
        contentOf(dto(kind: MessageKindDto.redacted, body: null)),
        const RedactedContent(),
      );
      expect(
        contentOf(dto(kind: MessageKindDto.undecryptable, body: null)),
        const UndecryptableContent(),
      );
      expect(
        contentOf(
          dto(
            kind: MessageKindDto.unsupported,
            body: null,
            eventType: 'm.image',
          ),
        ),
        const UnsupportedContent('m.image'),
      );
    });

    test('converte os estados de envio', () {
      expect(
        dto(sendState: SendStateDto.sending).toEntity().sendState,
        MessageSendState.sending,
      );
      expect(
        dto(sendState: SendStateDto.failed).toEntity().sendState,
        MessageSendState.failed,
      );
    });
  });

  group('MessageRepositoryImpl', () {
    late MockChatNativeDataSource native;
    late MessageRepositoryImpl repository;

    setUp(() {
      native = MockChatNativeDataSource();
      repository = MessageRepositoryImpl(native);
    });

    test('watchTimeline converte erros do stream em Err', () async {
      final controller = StreamController<List<Message>>();
      when(
        () => native.watchTimeline(roomId),
      ).thenAnswer((_) => controller.stream);

      final expectation = expectLater(
        repository.watchTimeline(roomId),
        emitsInOrder([
          isA<Ok<List<Message>>>(),
          isA<Err<List<Message>>>().having(
            (r) => r.failure,
            'failure',
            isA<RoomNotFoundFailure>(),
          ),
        ]),
      );
      controller
        ..add(const [])
        ..addError(const NativeException(NativeErrorKind.roomNotFound));
      await expectation;
      await controller.close();
    });

    test('loadOlderMessages repassa se o início foi alcançado', () async {
      when(
        () => native.paginateBackwards(roomId, count: 30),
      ).thenAnswer((_) async => true);

      final result = await repository.loadOlderMessages(roomId, count: 30);

      expect((result as Ok<bool>).value, isTrue);
    });

    test('loadOlderMessages limita a página ao máximo do Rust (u16)', () async {
      when(
        () => native.paginateBackwards(roomId, count: any(named: 'count')),
      ).thenAnswer((_) async => false);

      await repository.loadOlderMessages(roomId, count: 100000);

      verify(() => native.paginateBackwards(roomId, count: 0xFFFF)).called(1);
    });

    test('sendText converte NativeException em Failure', () async {
      when(() => native.sendText(roomId, 'oi')).thenThrow(
        const NativeException(NativeErrorKind.network),
      );

      final result = await repository.sendText(roomId, 'oi');

      expect((result as Err).failure, isA<NetworkFailure>());
    });

    test('retrySend e markAsRead delegam ao data source', () async {
      when(
        () => native.retrySend(roomId, 'txn1'),
      ).thenAnswer((_) async {});
      when(() => native.markAsRead(roomId)).thenAnswer((_) async {});

      expect(await repository.retrySend(roomId, 'txn1'), isA<Ok<void>>());
      expect(await repository.markAsRead(roomId), isA<Ok<void>>());
    });

    test('erro inesperado vira UnexpectedFailure', () async {
      when(() => native.markAsRead(roomId)).thenThrow(StateError('boom'));

      final result = await repository.markAsRead(roomId);

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });
}
