import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:matrix_desktop/features/chat/presentation/widgets/chat_panel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

const roomId = '!a:matrix.org';

void main() {
  late MockMessageRepository repository;
  late StreamController<Result<List<Message>>> timeline;

  final now = DateTime.now();
  Message message(
    String id,
    String body, {
    String sender = '@alice',
    bool isOwn = false,
    MessageSendState sendState = MessageSendState.sent,
    int minutesAgo = 0,
  }) => Message(
    id: id,
    senderId: sender,
    senderName: sender == '@alice' ? 'Alice' : 'Eu',
    content: TextContent(body),
    timestamp: now.subtract(Duration(minutes: minutesAgo)),
    isOwn: isOwn,
    sendState: sendState,
  );

  setUp(() {
    repository = MockMessageRepository();
    timeline = StreamController();
    when(
      () => repository.watchTimeline(roomId),
    ).thenAnswer((_) => timeline.stream);
    when(
      () => repository.loadOlderMessages(any(), count: any(named: 'count')),
    ).thenAnswer((_) async => const Ok(true));
    when(
      () => repository.markAsRead(any()),
    ).thenAnswer((_) async => const Ok<void>(null));
    when(
      () => repository.sendText(any(), any()),
    ).thenAnswer((_) async => const Ok<void>(null));
    when(
      () => repository.retrySend(any(), any()),
    ).thenAnswer((_) async => const Ok<void>(null));

    Get.put(
      ChatViewModel(
        watchTimeline: WatchTimelineUseCase(repository),
        loadOlderMessages: LoadOlderMessagesUseCase(repository),
        sendMessage: SendMessageUseCase(repository),
        retryMessage: RetryMessageUseCase(repository),
        markRoomAsRead: MarkRoomAsReadUseCase(repository),
      ),
    );
  });

  tearDown(() async {
    Get.reset();
    await timeline.close();
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatPanel(roomId: roomId)),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, List<Message> messages) async {
    timeline.add(Ok(messages));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('mostra carregamento e depois as mensagens agrupadas', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await emit(tester, [
      message(r'$1', 'bom dia', minutesAgo: 2),
      message(r'$2', 'tudo bem?', minutesAgo: 1),
    ]);

    expect(find.text('bom dia'), findsOneWidget);
    expect(find.text('tudo bem?'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget); // só no início do grupo
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Início da conversa'), findsOneWidget);
  });

  testWidgets('estado vazio convida a iniciar a conversa', (tester) async {
    await pumpPanel(tester);

    await emit(tester, const []);

    expect(find.text('Nenhuma mensagem ainda. Diga olá!'), findsOneWidget);
  });

  testWidgets('Enter envia e limpa o campo', (tester) async {
    await pumpPanel(tester);
    await emit(tester, const []);

    await tester.enterText(find.byKey(const Key('composer.input')), 'olá');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    verify(() => repository.sendText(roomId, 'olá')).called(1);
    expect(find.text('olá'), findsNothing);
  });

  testWidgets('botão enviar também envia', (tester) async {
    await pumpPanel(tester);
    await emit(tester, const []);

    await tester.enterText(find.byKey(const Key('composer.input')), 'oi');
    await tester.pump();
    await tester.tap(find.byKey(const Key('composer.send')));
    await tester.pump();

    verify(() => repository.sendText(roomId, 'oi')).called(1);
  });

  testWidgets('mensagem longa demais volta ao campo com o erro', (
    tester,
  ) async {
    await pumpPanel(tester);
    await emit(tester, const []);
    final tooLong = 'a' * (SendMessageUseCase.maxBodyBytes + 1);

    await tester.enterText(find.byKey(const Key('composer.input')), tooLong);
    await tester.pump();
    await tester.tap(find.byKey(const Key('composer.send')));
    await tester.pump();

    expect(find.text('A mensagem é longa demais.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('composer.input')),
    );
    expect(field.controller!.text, tooLong);
    verifyNever(() => repository.sendText(any(), any()));
  });

  testWidgets('mostra estados de envio e permite reenviar a que falhou', (
    tester,
  ) async {
    await pumpPanel(tester);

    await emit(tester, [
      message(
        'txn1',
        'enviando',
        sender: '@me',
        isOwn: true,
        sendState: MessageSendState.sending,
      ),
      message(
        'txn2',
        'falhou',
        sender: '@me',
        isOwn: true,
        sendState: MessageSendState.failed,
      ),
    ]);

    expect(find.byTooltip('Enviando'), findsOneWidget);
    expect(find.byTooltip('Falhou'), findsOneWidget);

    await tester.tap(find.byKey(const Key('message.retry.txn2')));
    await tester.pump();

    verify(() => repository.retrySend(roomId, 'txn2')).called(1);
  });

  testWidgets('conteúdos não textuais têm descrição', (tester) async {
    await pumpPanel(tester);

    timeline.add(
      Ok([
        Message(
          id: r'$1',
          senderId: '@alice',
          senderName: 'Alice',
          content: const UnsupportedContent('m.image'),
          timestamp: now,
          isOwn: false,
        ),
        Message(
          id: r'$2',
          senderId: '@alice',
          senderName: 'Alice',
          content: const RedactedContent(),
          timestamp: now,
          isOwn: false,
        ),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Tipo de mensagem não suportado (m.image).'),
      findsOneWidget,
    );
    expect(find.text('Mensagem apagada'), findsOneWidget);
  });

  testWidgets('botão enviar fica desativado com o campo vazio', (
    tester,
  ) async {
    await pumpPanel(tester);
    await emit(tester, const []);
    IconButton sendButton() =>
        tester.widget<IconButton>(find.byKey(const Key('composer.send')));

    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('composer.input')), '   ');
    await tester.pump();
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('composer.input')), 'oi');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('rolar para cima mostra o atalho para as mais recentes', (
    tester,
  ) async {
    await pumpPanel(tester);
    await emit(tester, [
      for (var i = 0; i < 60; i++)
        message('\$$i', 'mensagem $i', minutesAgo: 60 - i),
    ]);
    final jump = find.byKey(const Key('chat.jumpToLatest'));
    expect(jump, findsNothing);

    await tester.drag(
      find.byKey(const Key('chat.timeline')),
      const Offset(0, 1500),
    );
    await tester.pumpAndSettle();
    expect(jump, findsOneWidget);

    await tester.tap(jump);
    await tester.pumpAndSettle();
    expect(jump, findsNothing);
    expect(find.text('mensagem 59'), findsOneWidget);
  });
}
