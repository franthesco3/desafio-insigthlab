import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/repositories/room_repository.dart';

class WatchSyncStatusUseCase {
  const WatchSyncStatusUseCase(this._repository);

  final RoomRepository _repository;

  /// Ignora emissões repetidas para evitar rebuilds desnecessários na UI.
  Stream<SyncStatus> call() => _repository.watchSyncStatus().distinct();
}
