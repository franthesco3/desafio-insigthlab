import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:matrix_desktop/features/chat/presentation/widgets/chat_timeline.dart';
import 'package:matrix_desktop/features/chat/presentation/widgets/message_composer.dart';

/// Timeline e campo de mensagem da sala [roomId].
///
/// Deve receber uma `key` por sala: trocar de sala recria o painel, zerando
/// rolagem e rascunho.
class ChatPanel extends GetView<ChatViewModel> {
  const ChatPanel({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context) =>
      _ChatPanelBody(viewModel: controller, roomId: roomId);
}

/// Parte com estado: abre a sala no ViewModel ao ser criada.
class _ChatPanelBody extends StatefulWidget {
  const _ChatPanelBody({required this.viewModel, required this.roomId});

  final ChatViewModel viewModel;
  final String roomId;

  @override
  State<_ChatPanelBody> createState() => _ChatPanelBodyState();
}

class _ChatPanelBodyState extends State<_ChatPanelBody> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.open(widget.roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ChatTimeline(viewModel: widget.viewModel)),
        const Divider(height: 1),
        MessageComposer(viewModel: widget.viewModel),
      ],
    );
  }
}
