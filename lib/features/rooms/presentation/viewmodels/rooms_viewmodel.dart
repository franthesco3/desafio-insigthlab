import 'dart:async';

import 'package:get/get.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';

class RoomsViewModel extends GetxController {
  RoomsViewModel({
    required WatchRoomsUseCase watchRooms,
    required WatchSyncStatusUseCase watchSyncStatus,
  }) : _watchRooms = watchRooms,
       _watchSyncStatus = watchSyncStatus;

  final WatchRoomsUseCase _watchRooms;
  final WatchSyncStatusUseCase _watchSyncStatus;

  final state = Rx<ViewState<List<Room>>>(const Loading());
  final syncStatus = Rx<SyncStatus>(SyncStatus.idle);
  final RxString query = ''.obs;
  final selectedRoomId = RxnString();

  StreamSubscription<Result<List<Room>>>? _roomsSubscription;
  StreamSubscription<SyncStatus>? _syncSubscription;

  List<Room> get _rooms => switch (state.value) {
    Success(:final data) => data,
    _ => const [],
  };

  /// Salas exibidas, filtradas pela busca (sem diferenciar maiúsculas).
  List<Room> get visibleRooms {
    final term = query.value.trim().toLowerCase();
    if (term.isEmpty) return _rooms;
    return _rooms
        .where((room) => room.name.toLowerCase().contains(term))
        .toList();
  }

  Room? get selectedRoom {
    final id = selectedRoomId.value;
    return _rooms.firstWhereOrNull((room) => room.id == id);
  }

  @override
  void onInit() {
    super.onInit();
    _syncSubscription = _watchSyncStatus().listen(syncStatus.call);
    _subscribeToRooms();
  }

  @override
  void onClose() {
    unawaited(_roomsSubscription?.cancel());
    unawaited(_syncSubscription?.cancel());
    super.onClose();
  }

  void search(String value) => query.value = value;

  void select(String roomId) => selectedRoomId.value = roomId;

  /// Assina novamente a lista após uma falha.
  void retry() {
    state.value = const Loading();
    _subscribeToRooms();
  }

  void _subscribeToRooms() {
    unawaited(_roomsSubscription?.cancel());
    _roomsSubscription = _watchRooms().listen((result) {
      switch (result) {
        case Ok(:final value):
          state.value = Success(value);
        // Com dados já exibidos, uma falha posterior não apaga a lista: o
        // indicador de sync informa o problema.
        case Err(:final failure) when state.value is! Success:
          state.value = Failed(failure);
        case Err():
          break;
      }
    });
  }
}
