import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/ui/failure_messages.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/core/ui/widgets/status_message.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/room_tile.dart';

/// Coluna com busca e lista de salas.
class RoomsSidebar extends GetView<RoomsViewModel> {
  const RoomsSidebar({this.searchFocusNode, super.key});

  /// Permite que o atalho de busca (Ctrl/Cmd+K) foque o campo.
  final FocusNode? searchFocusNode;

  static String get _searchShortcutLabel =>
      defaultTargetPlatform == TargetPlatform.macOS ? '⌘K' : 'Ctrl+K';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextField(
            key: const Key('rooms.search'),
            focusNode: searchFocusNode,
            onChanged: controller.search,
            decoration: InputDecoration(
              hintText: 'Buscar salas ($_searchShortcutLabel)',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Obx(
            () => switch (controller.state.value) {
              Idle() || Loading() => const StatusMessage(
                icon: Icons.sync,
                text: 'Carregando salas…',
                showProgress: true,
              ),
              Failed(:final failure) => StatusMessage(
                icon: Icons.error_outline,
                text: failure.userMessage,
                action: TextButton(
                  onPressed: controller.retry,
                  child: const Text('Tentar de novo'),
                ),
              ),
              Success(:final data) when data.isEmpty => const StatusMessage(
                icon: Icons.forum_outlined,
                text: 'Você ainda não participa de nenhuma sala.',
              ),
              Success() => const _RoomList(),
            },
          ),
        ),
      ],
    );
  }
}

class _RoomList extends GetView<RoomsViewModel> {
  const _RoomList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rooms = controller.visibleRooms;
      final selectedId = controller.selectedRoomId.value;
      if (rooms.isEmpty) {
        return StatusMessage(
          icon: Icons.search_off,
          text: 'Nenhuma sala encontrada para "${controller.query.value}".',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return RoomTile(
            key: ValueKey(room.id),
            room: room,
            selected: room.id == selectedId,
            onTap: () => controller.select(room.id),
          );
        },
      );
    });
  }
}
