import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/repository_mocks.dart';

void main() {
  late MockRoomRepository repository;

  setUp(() => repository = MockRoomRepository());

  group('WatchRoomsUseCase', () {
    test('ordena por atividade recente e deixa salas sem atividade '
        'no fim, por nome', () async {
      final rooms = [
        Room(id: '!old', name: 'Antiga', lastActivity: DateTime(2026)),
        const Room(id: '!z', name: 'zeta'),
        Room(id: '!new', name: 'Nova', lastActivity: DateTime(2026, 10)),
        const Room(id: '!a', name: 'Alfa'),
      ];
      when(
        () => repository.watchRooms(),
      ).thenAnswer((_) => Stream.value(Ok(rooms)));

      final result = await WatchRoomsUseCase(repository)().first;

      final ids = (result as Ok<List<Room>>).value.map((room) => room.id);
      expect(ids, ['!new', '!old', '!a', '!z']);
    });

    test('repassa falhas sem alterar', () async {
      when(
        () => repository.watchRooms(),
      ).thenAnswer((_) => Stream.value(const Err(NetworkFailure())));

      final result = await WatchRoomsUseCase(repository)().first;

      expect((result as Err<List<Room>>).failure, const NetworkFailure());
    });
  });

  group('WatchSyncStatusUseCase', () {
    test('ignora estados repetidos em sequência', () {
      when(() => repository.watchSyncStatus()).thenAnswer(
        (_) => Stream.fromIterable([
          SyncStatus.syncing,
          SyncStatus.syncing,
          SyncStatus.running,
          SyncStatus.running,
          SyncStatus.offline,
        ]),
      );

      expect(
        WatchSyncStatusUseCase(repository)(),
        emitsInOrder([
          SyncStatus.syncing,
          SyncStatus.running,
          SyncStatus.offline,
          emitsDone,
        ]),
      );
    });
  });
}
