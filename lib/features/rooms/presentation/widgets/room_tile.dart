import 'package:flutter/material.dart';
import 'package:matrix_desktop/core/ui/date_formatting.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/room_avatar.dart';

class RoomTile extends StatelessWidget {
  const RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Room room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastActivity = room.lastActivity;
    final emphasis = room.hasUnread ? FontWeight.w700 : FontWeight.w400;

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      leading: RoomAvatar(seed: room.id, name: room.name),
      title: Row(
        children: [
          if (room.isEncrypted) ...[
            Icon(Icons.lock_outline, size: 14, color: theme.hintColor),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: emphasis),
            ),
          ),
          if (lastActivity != null)
            Text(
              formatShortTimestamp(lastActivity),
              style: theme.textTheme.labelSmall,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              room.lastMessagePreview ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: emphasis),
            ),
          ),
          if (room.hasUnread) ...[
            const SizedBox(width: 8),
            Badge(label: Text('${room.unreadCount}')),
          ],
        ],
      ),
    );
  }
}
