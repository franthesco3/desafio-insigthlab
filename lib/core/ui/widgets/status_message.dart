import 'package:flutter/material.dart';

/// Mensagem centralizada para estados de carregamento, vazio e erro.
class StatusMessage extends StatelessWidget {
  const StatusMessage({
    required this.icon,
    required this.text,
    this.action,
    this.showProgress = false,
    this.iconSize = 32,
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  /// Exibe um indicador de progresso no lugar do ícone.
  final bool showProgress;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: iconSize, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            ?action,
          ],
        ),
      ),
    );
  }
}
