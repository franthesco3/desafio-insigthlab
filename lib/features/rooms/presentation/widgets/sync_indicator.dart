import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';

class SyncIndicator extends GetView<RoomsViewModel> {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final (label, color) = switch (controller.syncStatus.value) {
        SyncStatus.idle || SyncStatus.syncing => (
          'Sincronizando…',
          Colors.amber,
        ),
        SyncStatus.running => ('Conectado', Colors.green),
        SyncStatus.offline => ('Sem conexão', Colors.grey),
        SyncStatus.error => ('Erro de sincronização', Colors.red),
      };
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 8),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
    });
  }
}
