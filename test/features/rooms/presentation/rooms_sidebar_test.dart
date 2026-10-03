import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:matrix_desktop/features/home/presentation/widgets/conversation_area.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/rooms_sidebar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

void main() {
  late StreamController<Result<List<Room>>> rooms;

  setUp(() {
    rooms = StreamController();
    final repository = MockRoomRepository();
    when(repository.watchRooms).thenAnswer((_) => rooms.stream);
    when(
      repository.watchSyncStatus,
    ).thenAnswer((_) => const Stream<SyncStatus>.empty());
    final messages = MockMessageRepository();
    when(
      () => messages.watchTimeline(any()),
    ).thenAnswer((_) => Stream.value(const Ok(<Message>[])));
    when(
      () => messages.loadOlderMessages(any(), count: any(named: 'count')),
    ).thenAnswer((_) async => const Ok(true));
    Get
      ..put(
        ChatViewModel(
          watchTimeline: WatchTimelineUseCase(messages),
          loadOlderMessages: LoadOlderMessagesUseCase(messages),
          sendMessage: SendMessageUseCase(messages),
          retryMessage: RetryMessageUseCase(messages),
          markRoomAsRead: MarkRoomAsReadUseCase(messages),
        ),
      )
      ..put(
        RoomsViewModel(
          watchRooms: WatchRoomsUseCase(repository),
          watchSyncStatus: WatchSyncStatusUseCase(repository),
        ),
      );
  });

  tearDown(() async {
    Get.reset();
    await rooms.close();
  });

  Future<void> pumpHome(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            SizedBox(width: 320, child: RoomsSidebar()),
            Expanded(child: ConversationArea()),
          ],
        ),
      ),
    ),
  );

  testWidgets('exibe carregamento e depois a lista de salas', (tester) async {
    await pumpHome(tester);
    expect(find.text('Carregando salas…'), findsOneWidget);

    rooms.add(
      const Ok([
        Room(id: '!a', name: 'Geral', lastMessagePreview: 'bom dia'),
        Room(id: '!b', name: 'Projeto', unreadCount: 3),
      ]),
    );
    await tester.pump();

    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('bom dia'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('mostra estado vazio', (tester) async {
    await pumpHome(tester);

    rooms.add(const Ok([]));
    await tester.pump();

    expect(
      find.text('Você ainda não participa de nenhuma sala.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra erro com opção de tentar de novo', (tester) async {
    await pumpHome(tester);

    rooms.add(const Err(NetworkFailure()));
    await tester.pump();

    expect(
      find.text('Sem conexão com a internet. Verifique sua rede.'),
      findsOneWidget,
    );
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('selecionar uma sala abre a conversa', (tester) async {
    await pumpHome(tester);
    rooms.add(const Ok([Room(id: '!a', name: 'Geral')]));
    await tester.pump();
    expect(
      find.text('Selecione uma sala para ver a conversa.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Geral'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Selecione uma sala para ver a conversa.'), findsNothing);
    expect(find.text('Geral'), findsNWidgets(2)); // lista + cabeçalho
    expect(find.text('Nenhuma mensagem ainda. Diga olá!'), findsOneWidget);
    expect(find.byKey(const Key('composer.input')), findsOneWidget);
  });

  testWidgets('busca sem resultados avisa o usuário', (tester) async {
    await pumpHome(tester);
    rooms.add(const Ok([Room(id: '!a', name: 'Geral')]));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('rooms.search')), 'xyz');
    await tester.pump();

    expect(find.text('Nenhuma sala encontrada para "xyz".'), findsOneWidget);
  });
}
