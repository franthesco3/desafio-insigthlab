import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/ui/date_formatting.dart';
import 'package:matrix_desktop/core/ui/failure_messages.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/core/ui/widgets/status_message.dart';
import 'package:matrix_desktop/features/chat/presentation/timeline_entries.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:matrix_desktop/features/chat/presentation/widgets/message_bubble.dart';

/// Lista de mensagens, com as mais recentes embaixo. Rolar até o topo carrega
/// mensagens anteriores.
class ChatTimeline extends StatefulWidget {
  const ChatTimeline({required this.viewModel, super.key});

  final ChatViewModel viewModel;

  @override
  State<ChatTimeline> createState() => _ChatTimelineState();
}

class _ChatTimelineState extends State<ChatTimeline> {
  /// Distância do topo (em pixels) que dispara o carregamento de mensagens
  /// anteriores, para que elas cheguem antes de o usuário alcançar o fim.
  static const _loadOlderThreshold = 400.0;

  /// Distância do fim da conversa a partir da qual aparece o botão de voltar
  /// às mensagens mais recentes.
  static const _jumpToLatestThreshold = 600.0;

  final _scrollController = ScrollController();
  final ValueNotifier<bool> _showJumpToLatest = ValueNotifier(false);

  ChatViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showJumpToLatest.dispose();
    super.dispose();
  }

  // A lista é invertida: o "topo" visual é o fim da rolagem.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadOlderThreshold) {
      unawaited(_viewModel.loadOlder());
    }
    _showJumpToLatest.value = position.pixels > _jumpToLatestThreshold;
  }

  Future<void> _jumpToLatest() => _scrollController.animateTo(
    0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  /// Se as mensagens não preenchem a tela, não há rolagem para disparar a
  /// paginação: carrega mais até preencher ou chegar ao início da sala.
  void _fillViewportIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_viewModel.olderMessagesFailure.value != null) return;
      if (_scrollController.position.maxScrollExtent <= _loadOlderThreshold) {
        unawaited(_viewModel.loadOlder());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => switch (_viewModel.state.value) {
        Idle() || Loading() => const Center(
          child: CircularProgressIndicator(),
        ),
        Failed(:final failure) => StatusMessage(
          iconSize: 40,
          icon: Icons.error_outline,
          text: failure.userMessage,
          action: TextButton(
            onPressed: _viewModel.retry,
            child: const Text('Tentar de novo'),
          ),
        ),
        Success() => _buildList(),
      },
    );
  }

  Widget _buildList() {
    final entries = _viewModel.entries;
    final reachedStart = _viewModel.reachedStart.value;
    if (entries.isEmpty && reachedStart) {
      return const StatusMessage(
        iconSize: 40,
        icon: Icons.forum_outlined,
        text: 'Nenhuma mensagem ainda. Diga olá!',
      );
    }
    _fillViewportIfNeeded();

    final list = ListView.builder(
      key: const Key('chat.timeline'),
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // +1: indicador de carregamento/início da sala no topo.
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) return _HistoryHeader(_viewModel);
        return switch (entries[entries.length - 1 - index]) {
          DayDivider(:final day) => _DayDividerTile(day),
          MessageEntry(:final message, :final startsGroup) => MessageBubble(
            key: ValueKey(message.id),
            message: message,
            showSender: startsGroup,
            onRetry: () => unawaited(_viewModel.resend(message)),
          ),
        };
      },
    );

    return Stack(
      children: [
        list,
        Positioned(
          right: 16,
          bottom: 16,
          child: ValueListenableBuilder(
            valueListenable: _showJumpToLatest,
            builder: (context, visible, _) => visible
                ? FloatingActionButton.small(
                    key: const Key('chat.jumpToLatest'),
                    tooltip: 'Ir para as mensagens mais recentes',
                    onPressed: _jumpToLatest,
                    child: const Icon(Icons.keyboard_arrow_down),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Topo da lista: carregando, erro com nova tentativa ou início da sala.
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader(this.viewModel);

  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Obx(() {
          final failure = viewModel.olderMessagesFailure.value;
          if (viewModel.isLoadingOlder.value) {
            return const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (failure != null) {
            return TextButton.icon(
              onPressed: viewModel.loadOlder,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Não foi possível carregar mensagens anteriores. '
                'Tentar de novo',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          if (viewModel.reachedStart.value) {
            return Text(
              'Início da conversa',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}

class _DayDividerTile extends StatelessWidget {
  const _DayDividerTile(this.day);

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatDayLabel(day),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
