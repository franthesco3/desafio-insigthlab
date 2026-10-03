import 'dart:async';

import 'package:matrix_desktop/core/native/native_result.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/rooms/data/datasources/rooms_native_datasource.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/repositories/room_repository.dart';

final class RoomRepositoryImpl implements RoomRepository {
  const RoomRepositoryImpl(this._native);

  final RoomsNativeDataSource _native;

  @override
  Stream<Result<List<Room>>> watchRooms() => _native.watchRooms().asResults();

  /// Uma falha no próprio stream de estado também é um estado: `error`.
  @override
  Stream<SyncStatus> watchSyncStatus() => _native.watchSyncStatus().transform(
    StreamTransformer.fromHandlers(
      handleError: (_, _, sink) => sink.add(SyncStatus.error),
    ),
  );
}
