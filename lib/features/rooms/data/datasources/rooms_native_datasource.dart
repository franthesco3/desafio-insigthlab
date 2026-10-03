import 'package:matrix_desktop/core/native/bridge/api/rooms.dart' as native;
import 'package:matrix_desktop/core/native/native_call.dart';
import 'package:matrix_desktop/features/rooms/data/mappers/room_mapper.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';

/// Streams de sync e salas vindos do Rust. O primeiro a ser assinado inicia
/// o sync. Erros chegam como `NativeException`.
abstract interface class RoomsNativeDataSource {
  Stream<List<Room>> watchRooms();

  Stream<SyncStatus> watchSyncStatus();
}

final class FrbRoomsNativeDataSource implements RoomsNativeDataSource {
  const FrbRoomsNativeDataSource();

  @override
  Stream<List<Room>> watchRooms() => guardNativeStream(
    native.watchRooms(),
  ).map((rooms) => [for (final room in rooms) room.toEntity()]);

  @override
  Stream<SyncStatus> watchSyncStatus() =>
      guardNativeStream(native.watchSyncState()).map((s) => s.toEntity());
}
