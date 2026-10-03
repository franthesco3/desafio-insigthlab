import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';

abstract interface class RoomRepository {
  /// Emite a lista completa de salas a cada atualização do sync.
  Stream<Result<List<Room>>> watchRooms();

  Stream<SyncStatus> watchSyncStatus();
}
