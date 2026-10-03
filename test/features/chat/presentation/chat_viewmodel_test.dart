import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:matrix_desktop/features/chat/presentation/timeline_entries.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

const roomA = '!a:matrix.org';
const roomB = '!b:matrix.org';

Message message(
  String id, {
  MessageSendState sendState = MessageSendState.sent,
  bool isOwn = false,
}) => Message(
  id: id,
  senderId: isOwn ? '@me' : '@alice',
  senderName: isOwn ? 'Eu' : 'Alice',
  content: TextContent(id),
  timestamp: DateTime(2026, 10, 3, 12),
  isOwn: isOwn,
  sendState: sendState,
);

void main() {
  late MockMessageRepository repository;
  late Map<String, StreamController<Result<List<Message>>>> timelines;
  late ChatViewModel viewModel;

  setUpAll(() => Get.testMode = true);

  setUp(() {
    repository = MockMessageRepository();
    timelines = {
      roomA: StreamController.broadcast(),
      roomB: StreamController.broadcast(),
    };
    when(
      () => repository.watchTimeline(any()),
    ).thenAnswer((call) => timelines[call.positionalArguments.first]!.stream);
    when(
      () => repository.loadOlderMessages(any(), count: any(named: 'count')),
    ).thenAnswer((_) async => const Ok(false));
    when(
      () => repository.markAsRead(any()),
    ).thenAnswer((_) async => const Ok<void>(null));
    when(
      () => repository.sendText(any(), any()),
    ).thenAnswer((_) async => const Ok<void>(null));

    viewModel = ChatViewModel(
      watchTimeline: WatchTimelineUseCase(repository),
      loadOlderMessages: LoadOlderMessagesUseCase(repository),
      sendMessage: SendMessageUseCase(repository),
      retryMessage: RetryMessageUseCase(repository),
      markRoomAsRead: MarkRoomAsReadUseCase(repository),
    );
  });

  tearDown(() async {
    viewModel.onClose();
    for (final controller in timelines.values) {
      await controller.close();
    }
  });

  Future<void> emit(String roomId, Result<List<Message>> result) async {
    timelines[roomId]!.add(result);
    await pumpEventQueue();
  }

  test('open carrega a timeline e já pede mensagens anteriores', () async {
    viewModel.open(roomA);
    expect(viewModel.state.value, isA<Loading<List<Message>>>());

    await emit(roomA, Ok([message(r'$1')]));

    expect(viewModel.state.value, isA<Success<List<Message>>>());
    expect(viewModel.entries.whereType<MessageEntry>(), hasLength(1));
    verify(
      () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
    ).called(1);
  });

  test('abrir a mesma sala de novo não reinicia a assinatura', () async {
    viewModel
      ..open(roomA)
      ..open(roomA);

    verify(() => repository.watchTimeline(roomA)).called(1);
  });

  test('trocar de sala ignora atualizações da sala anterior', () async {
    viewModel.open(roomA);
    await emit(roomA, Ok([message(r'$a')]));

    viewModel.open(roomB);
    await emit(roomA, Ok([message(r'$a'), message(r'$a2')]));

    expect(viewModel.roomId, roomB);
    expect(viewModel.state.value, isA<Loading<List<Message>>>());
  });

  test('falha inicial exibe erro e retry assina de novo', () async {
    viewModel.open(roomA);
    await emit(roomA, const Err(RoomNotFoundFailure()));

    expect(viewModel.state.value, isA<Failed<List<Message>>>());

    viewModel.retry();
    await emit(roomA, const Ok([]));

    expect(viewModel.state.value, isA<Success<List<Message>>>());
  });

  test('falha depois de exibir mensagens mantém a conversa', () async {
    viewModel.open(roomA);
    await emit(roomA, Ok([message(r'$1')]));
    await emit(roomA, const Err(NetworkFailure()));

    expect(viewModel.state.value, isA<Success<List<Message>>>());
  });

  group('loadOlder', () {
    test('marca o início da sala e para de paginar', () async {
      when(
        () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
      ).thenAnswer((_) async => const Ok(true));

      viewModel.open(roomA);
      await pumpEventQueue();
      await viewModel.loadOlder();

      expect(viewModel.reachedStart.value, isTrue);
      verify(
        () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
      ).called(1);
    });

    test('ignora chamadas enquanto já está carregando', () async {
      final pending = Completer<Result<bool>>();
      when(
        () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
      ).thenAnswer((_) => pending.future);

      viewModel.open(roomA); // dispara o primeiro carregamento
      await viewModel.loadOlder();

      expect(viewModel.isLoadingOlder.value, isTrue);
      verify(
        () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
      ).called(1);

      pending.complete(const Ok(false));
      await pumpEventQueue();
      expect(viewModel.isLoadingOlder.value, isFalse);
    });

    test('expõe a falha para nova tentativa', () async {
      when(
        () => repository.loadOlderMessages(roomA, count: any(named: 'count')),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      viewModel.open(roomA);
      await pumpEventQueue();

      expect(viewModel.olderMessagesFailure.value, isA<NetworkFailure>());
      expect(viewModel.isLoadingOlder.value, isFalse);
    });
  });

  group('send', () {
    test('aceita a mensagem e limpa o erro anterior', () async {
      viewModel
        ..open(roomA)
        ..sendFailure.value = const NetworkFailure();

      final accepted = await viewModel.send('olá');

      expect(accepted, isTrue);
      expect(viewModel.sendFailure.value, isNull);
      verify(() => repository.sendText(roomA, 'olá')).called(1);
    });

    test('rejeita mensagem vazia sem chamar o repositório', () async {
      viewModel.open(roomA);

      final accepted = await viewModel.send('   ');

      expect(accepted, isFalse);
      expect(viewModel.sendFailure.value, isA<ValidationFailure>());
      verifyNever(() => repository.sendText(any(), any()));
    });

    test('sem sala aberta não envia', () async {
      expect(await viewModel.send('olá'), isFalse);
    });
  });

  test('resend reenvia mensagem que falhou', () async {
    final failed = message(
      'txn1',
      isOwn: true,
      sendState: MessageSendState.failed,
    );
    when(
      () => repository.retrySend(roomA, 'txn1'),
    ).thenAnswer((_) async => const Ok<void>(null));

    viewModel.open(roomA);
    await viewModel.resend(failed);

    verify(() => repository.retrySend(roomA, 'txn1')).called(1);
    expect(viewModel.sendFailure.value, isNull);
  });

  group('recibo de leitura', () {
    test('marca como lida só quando chega mensagem confirmada nova', () async {
      viewModel.open(roomA);

      await emit(roomA, Ok([message(r'$1')]));
      await emit(roomA, Ok([message(r'$1')])); // mesma última mensagem
      await emit(
        roomA,
        Ok([
          message(r'$1'),
          message('txn', isOwn: true, sendState: MessageSendState.sending),
        ]),
      );
      verify(() => repository.markAsRead(roomA)).called(1);

      await emit(roomA, Ok([message(r'$1'), message(r'$2')]));
      verify(() => repository.markAsRead(roomA)).called(1);
    });
  });

  test('onClose cancela a assinatura da timeline', () async {
    viewModel
      ..open(roomA)
      ..onClose();

    expect(timelines[roomA]!.hasListener, isFalse);
  });
}
