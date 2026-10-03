import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';
import 'package:matrix_desktop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:matrix_desktop/features/home/presentation/views/home_view.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/auth_mocks.dart';
import '../../../mocks/repository_mocks.dart';

void main() {
  setUp(() {
    final rooms = MockRoomRepository();
    when(rooms.watchRooms).thenAnswer(
      (_) => Stream.value(const Ok([Room(id: '!a', name: 'Geral')])),
    );
    when(
      rooms.watchSyncStatus,
    ).thenAnswer((_) => Stream.value(SyncStatus.running));
    Get
      ..put(
        HomeViewModel(
          logout: MockLogoutUseCase(),
          sessionService: SessionService()..start(testSession),
          navigator: MockAppNavigator(),
        ),
      )
      ..put(
        RoomsViewModel(
          watchRooms: WatchRoomsUseCase(rooms),
          watchSyncStatus: WatchSyncStatusUseCase(rooms),
        ),
      );
  });

  tearDown(Get.reset);

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeView()));
    await tester.pump();
  }

  testWidgets('exibe a conta, a lista de salas e o painel vazio', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text(testSession.userId), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);
    expect(
      find.text('Selecione uma sala para ver a conversa.'),
      findsOneWidget,
    );
  });

  for (final modifier in [
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.meta,
  ]) {
    testWidgets('${modifier.keyLabel}+K foca a busca de salas', (
      tester,
    ) async {
      await pumpHome(tester);
      EditableText search() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('rooms.search')),
          matching: find.byType(EditableText),
        ),
      );
      expect(search().focusNode.hasFocus, isFalse);

      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();

      expect(search().focusNode.hasFocus, isTrue);
    });
  }
}
