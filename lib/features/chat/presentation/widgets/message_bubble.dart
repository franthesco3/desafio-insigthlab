import 'package:flutter/material.dart';
import 'package:matrix_desktop/core/ui/date_formatting.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';

/// Uma mensagem da conversa. As próprias ficam à direita, com o estado de
/// envio; as dos outros, à esquerda, com o nome do autor no início do grupo.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.showSender,
    required this.onRetry,
    super.key,
  });

  final Message message;
  final bool showSender;
  final VoidCallback onRetry;

  static const _maxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOwn = message.isOwn;

    return Padding(
      padding: EdgeInsets.only(top: showSender ? 12 : 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            crossAxisAlignment: isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showSender && !isOwn)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isOwn
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Content(message.content),
                      const SizedBox(height: 2),
                      _Footer(message: message),
                    ],
                  ),
                ),
              ),
              if (message.canRetry)
                TextButton.icon(
                  key: Key('message.retry.${message.id}'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Falhou ao enviar. Tentar de novo'),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.content);

  final MessageContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.hintColor,
    );
    return switch (content) {
      TextContent(:final body) => SelectableText(body),
      RedactedContent() => Text('Mensagem apagada', style: muted),
      UndecryptableContent() => Text(
        'Não foi possível descriptografar esta mensagem.',
        style: muted,
      ),
      UnsupportedContent(:final type) => Text(
        'Tipo de mensagem não suportado ($type).',
        style: muted,
      ),
    };
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(color: theme.hintColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: formatFullTimestamp(message.timestamp),
          child: Text(formatTime(message.timestamp), style: style),
        ),
        if (message.isOwn) ...[
          const SizedBox(width: 4),
          _SendStateIcon(message.sendState),
        ],
      ],
    );
  }
}

class _SendStateIcon extends StatelessWidget {
  const _SendStateIcon(this.state);

  final MessageSendState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = switch (state) {
      MessageSendState.sending => (
        Icons.schedule,
        'Enviando',
        theme.hintColor,
      ),
      MessageSendState.sent => (Icons.done, 'Enviada', theme.hintColor),
      MessageSendState.failed => (
        Icons.error_outline,
        'Falhou',
        theme.colorScheme.error,
      ),
    };
    return Tooltip(
      message: label,
      child: Icon(icon, size: 14, color: color, semanticLabel: label),
    );
  }
}
