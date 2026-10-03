import 'dart:async';

import 'package:get/get.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/ui/view_state.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:matrix_desktop/features/chat/presentation/timeline_entries.dart';

/// Conversa da sala aberta: timeline, paginação e envio.
class ChatViewModel extends GetxController {
  ChatViewModel({
    required WatchTimelineUseCase watchTimeline,
    required LoadOlderMessagesUseCase loadOlderMessages,
    required SendMessageUseCase sendMessage,
    required RetryMessageUseCase retryMessage,
    required MarkRoomAsReadUseCase markRoomAsRead,
  }) : _watchTimeline = watchTimeline,
       _loadOlderMessages = loadOlderMessages,
       _sendMessage = sendMessage,
       _retryMessage = retryMessage,
       _markRoomAsRead = markRoomAsRead;

  final WatchTimelineUseCase _watchTimeline;
  final LoadOlderMessagesUseCase _loadOlderMessages;
  final SendMessageUseCase _sendMessage;
  final RetryMessageUseCase _retryMessage;
  final MarkRoomAsReadUseCase _markRoomAsRead;

  final state = Rx<ViewState<List<Message>>>(const Idle());
  final RxBool isLoadingOlder = false.obs;
  final RxBool reachedStart = false.obs;
  final olderMessagesFailure = Rxn<Failure>();

  /// Último erro de envio ou reenvio, exibido junto ao campo de mensagem.
  final sendFailure = Rxn<Failure>();

  String? _roomId;
  String? _lastReadMessageId;
  StreamSubscription<Result<List<Message>>>? _timelineSubscription;

  String? get roomId => _roomId;

  List<TimelineEntry> get entries => switch (state.value) {
    Success(:final data) => buildTimelineEntries(data),
    _ => const [],
  };

  @override
  void onClose() {
    unawaited(_timelineSubscription?.cancel());
    super.onClose();
  }

  /// Abre a conversa da sala, descartando a anterior.
  void open(String roomId) {
    if (roomId == _roomId) return;
    _roomId = roomId;
    _lastReadMessageId = null;
    isLoadingOlder.value = false;
    reachedStart.value = false;
    olderMessagesFailure.value = null;
    sendFailure.value = null;
    _subscribe();
  }

  /// Assina novamente a timeline após uma falha.
  void retry() {
    if (_roomId == null) return;
    _subscribe();
  }

  Future<void> loadOlder() async {
    final roomId = _roomId;
    if (roomId == null || isLoadingOlder.value || reachedStart.value) return;

    isLoadingOlder.value = true;
    olderMessagesFailure.value = null;
    final result = await _loadOlderMessages(roomId);
    // A sala mudou durante o carregamento: `open` já reiniciou o estado.
    if (roomId != _roomId) return;

    isLoadingOlder.value = false;
    switch (result) {
      case Ok(:final value):
        reachedStart.value = value;
      case Err(:final failure):
        olderMessagesFailure.value = failure;
    }
  }

  /// Retorna `true` quando a mensagem foi aceita (o campo pode ser limpo).
  Future<bool> send(String body) async {
    final roomId = _roomId;
    if (roomId == null) return false;

    sendFailure.value = null;
    final result = await _sendMessage(roomId, body);
    switch (result) {
      case Ok():
        return true;
      case Err(:final failure):
        sendFailure.value = failure;
        return false;
    }
  }

  Future<void> resend(Message message) async {
    final roomId = _roomId;
    if (roomId == null) return;

    sendFailure.value = null;
    final result = await _retryMessage(roomId, message);
    if (result case Err(:final failure)) sendFailure.value = failure;
  }

  void _subscribe() {
    final roomId = _roomId;
    if (roomId == null) return;

    state.value = const Loading();
    unawaited(_timelineSubscription?.cancel());
    _timelineSubscription = _watchTimeline(roomId).listen((result) {
      switch (result) {
        case Ok(:final value):
          state.value = Success(value);
          _markAsReadIfNeeded(roomId, value);
        // Com mensagens já exibidas, uma falha posterior não apaga a
        // conversa: o indicador de sync informa o problema.
        case Err(:final failure) when state.value is! Success:
          state.value = Failed(failure);
        case Err():
          break;
      }
    });
    unawaited(loadOlder());
  }

  /// Envia o recibo de leitura só quando chega uma mensagem nova confirmada
  /// pelo servidor, evitando uma requisição a cada atualização da timeline.
  void _markAsReadIfNeeded(String roomId, List<Message> messages) {
    final latest = messages
        .where((message) => message.sendState == MessageSendState.sent)
        .lastOrNull;
    if (latest == null || latest.id == _lastReadMessageId) return;
    _lastReadMessageId = latest.id;
    // Falhar ao marcar como lida não afeta a conversa.
    unawaited(_markRoomAsRead(roomId));
  }
}
