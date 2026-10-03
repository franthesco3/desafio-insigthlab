import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

void main() {
  late MockRoomRepository repository;
  late StreamController<Result<List<Room>>> rooms;
  late StreamController<SyncStatus> syncStatus;
  late RoomsViewModel viewModel;

  const general = Room(id: '!general', name: 'Geral');
  const random = Room(id: '!random', name: 'Aleatório');

  setUpAll(() => Get.testMode = true);

  setUp(() {
    repository = MockRoomRepository();
    rooms = StreamController.broadcast();
    syncStatus = StreamController.broadcast();
    when(repository.watchRooms).thenAnswer((_) => rooms.stream);
    when(repository.watchSyncStatus).thenAnswer((_) => syncStatus.stream);
    viewModel = RoomsViewModel(
      watchRooms: WatchRoomsUseCase(repository),
      watchSyncStatus: WatchSyncStatusUseCase(repository),
    )..onInit();
  });

  tearDown(() async {
    viewModel.onClose();
    await rooms.close();
    await syncStatus.close();
  });

  Future<void> emitRooms(List<Room> value) async {
    rooms.add(Ok(value));
    await pumpEventQueue();
  }

  test('começa carregando e exibe as salas recebidas', () async {
    expect(viewModel.state.value, isA<Loading<List<Room>>>());

    await emitRooms([general, random]);

    expect(viewModel.visibleRooms, [random, general]); // ordem alfabética
  });

  test('acompanha o estado do sync', () async {
    syncStatus.add(SyncStatus.running);
    await pumpEventQueue();

    expect(viewModel.syncStatus.value, SyncStatus.running);
  });

  test('busca filtra por nome sem diferenciar maiúsculas', () async {
    await emitRooms([general, random]);

    viewModel.search('  GER ');

    expect(viewModel.visibleRooms, [general]);
  });

  test('seleção acompanha atualizações e some se a sala sair', () async {
    await emitRooms([general, random]);
    viewModel.select(general.id);
    expect(viewModel.selectedRoom, general);

    const renamed = Room(id: '!general', name: 'Geral (renomeada)');
    await emitRooms([renamed, random]);
    expect(viewModel.selectedRoom, renamed);

    await emitRooms([random]);
    expect(viewModel.selectedRoom, isNull);
  });

  test('falha antes de qualquer dado exibe erro e permite repetir', () async {
    rooms.add(const Err(NetworkFailure()));
    await pumpEventQueue();
    expect(viewModel.state.value, isA<Failed<List<Room>>>());

    viewModel.retry();
    expect(viewModel.state.value, isA<Loading<List<Room>>>());
    await emitRooms([general]);

    expect(viewModel.visibleRooms, [general]);
    verify(repository.watchRooms).called(2);
  });

  test('falha depois de já haver dados mantém a lista', () async {
    await emitRooms([general]);

    rooms.add(const Err(NetworkFailure()));
    await pumpEventQueue();

    expect(viewModel.visibleRooms, [general]);
  });

  test('onClose cancela as assinaturas', () async {
    viewModel.onClose();

    expect(rooms.hasListener, isFalse);
    expect(syncStatus.hasListener, isFalse);
  });
}
