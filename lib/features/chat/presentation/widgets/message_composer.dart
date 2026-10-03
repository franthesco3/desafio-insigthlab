import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/core/ui/failure_messages.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';

/// Campo de mensagem. Enter envia; Shift+Enter quebra a linha.
class MessageComposer extends StatefulWidget {
  const MessageComposer({required this.viewModel, super.key});

  final ChatViewModel viewModel;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  late final _focusNode = FocusNode(onKeyEvent: _onKeyEvent);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is! KeyDownEvent ||
        !isEnter ||
        HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    unawaited(_send());
    return KeyEventResult.handled;
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    // Limpa antes do envio para permitir digitar a próxima mensagem; o texto
    // volta ao campo se for rejeitado.
    _controller.clear();
    final accepted = await widget.viewModel.send(text);
    if (!accepted && mounted && _controller.text.isEmpty) {
      _controller.text = text;
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final failure = widget.viewModel.sendFailure.value;
            if (failure == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                failure.userMessage,
                key: const Key('composer.error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('composer.input'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Escreva uma mensagem (Shift+Enter quebra a linha)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, _) => IconButton.filled(
                  key: const Key('composer.send'),
                  tooltip: 'Enviar (Enter)',
                  icon: const Icon(Icons.send),
                  onPressed: value.text.trim().isEmpty ? null : _send,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
