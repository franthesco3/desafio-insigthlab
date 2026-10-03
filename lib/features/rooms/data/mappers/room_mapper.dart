import 'package:matrix_desktop/core/native/bridge/api/rooms.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';

extension RoomSummaryDtoMapper on RoomSummaryDto {
  Room toEntity() {
    final timestamp = lastActivityMs;
    return Room(
      id: roomId,
      name: name,
      lastMessagePreview: lastMessagePreview,
      lastActivity: timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp),
      unreadCount: unreadCount,
      isEncrypted: isEncrypted,
    );
  }
}

extension SyncStateDtoMapper on SyncStateDto {
  SyncStatus toEntity() => switch (this) {
    SyncStateDto.idle => SyncStatus.idle,
    SyncStateDto.syncing => SyncStatus.syncing,
    SyncStateDto.running => SyncStatus.running,
    SyncStateDto.offline => SyncStatus.offline,
    SyncStateDto.error => SyncStatus.error,
  };
}
