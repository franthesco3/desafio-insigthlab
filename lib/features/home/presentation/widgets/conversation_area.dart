import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/features/chat/presentation/widgets/chat_panel.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/room_avatar.dart';

/// Painel direito: cabeçalho e conversa da sala selecionada.
class ConversationArea extends GetView<RoomsViewModel> {
  const ConversationArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final room = controller.selectedRoom;
      if (room == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: theme.hintColor),
              const SizedBox(height: 12),
              const Text('Selecione uma sala para ver a conversa.'),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                RoomAvatar(seed: room.id, name: room.name, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    room.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (room.isEncrypted)
                  Tooltip(
                    message: 'Sala criptografada',
                    child: Icon(Icons.lock_outline, color: theme.hintColor),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ChatPanel(key: ValueKey(room.id), roomId: room.id),
          ),
        ],
      );
    });
  }
}
