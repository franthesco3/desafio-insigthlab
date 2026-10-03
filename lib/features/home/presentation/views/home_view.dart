import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:matrix_desktop/features/home/presentation/widgets/conversation_area.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/rooms_sidebar.dart';
import 'package:matrix_desktop/features/rooms/presentation/widgets/sync_indicator.dart';

class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => _HomeLayout(viewModel: controller);
}

/// Layout em duas colunas com o atalho Ctrl/Cmd+K para buscar salas.
class _HomeLayout extends StatefulWidget {
  const _HomeLayout({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<_HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<_HomeLayout> {
  static const _sidebarWidth = 320.0;

  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void focusSearch() => _searchFocusNode.requestFocus();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            focusSearch,
      },
      // Garante que os atalhos funcionem mesmo sem nenhum campo focado.
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: _sidebarWidth,
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Column(
                    children: [
                      _AccountHeader(viewModel: widget.viewModel),
                      Expanded(
                        child: RoomsSidebar(searchFocusNode: _searchFocusNode),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              const Expanded(child: ConversationArea()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.viewModel});

  final HomeViewModel viewModel;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'A sessão será encerrada e os dados locais desta conta serão '
          'apagados deste computador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await viewModel.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.userId,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const SyncIndicator(),
              ],
            ),
          ),
          Obx(
            () => viewModel.isLoggingOut.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    key: const Key('home.logout'),
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout),
                    onPressed: () => _confirmLogout(context),
                  ),
          ),
        ],
      ),
    );
  }
}
