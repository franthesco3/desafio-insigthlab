import 'package:equatable/equatable.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';

/// Item exibido na conversa: uma mensagem ou um divisor de dia.
sealed class TimelineEntry extends Equatable {
  const TimelineEntry();
}

final class DayDivider extends TimelineEntry {
  const DayDivider(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

final class MessageEntry extends TimelineEntry {
  const MessageEntry(this.message, {required this.startsGroup});

  final Message message;

  /// Primeira mensagem de uma sequência do mesmo autor: exibe o nome.
  final bool startsGroup;

  @override
  List<Object?> get props => [message, startsGroup];
}

/// Intervalo máximo entre mensagens do mesmo autor para mantê-las no mesmo
/// grupo.
const groupingWindow = Duration(minutes: 5);

/// Agrupa mensagens consecutivas do mesmo autor e insere um divisor a cada
/// novo dia. [messages] vem da mais antiga para a mais recente.
List<TimelineEntry> buildTimelineEntries(List<Message> messages) {
  final entries = <TimelineEntry>[];
  Message? previous;
  for (final message in messages) {
    final newDay = previous == null || !_sameDay(previous, message);
    if (newDay) entries.add(DayDivider(_dayOf(message.timestamp)));

    final startsGroup =
        newDay ||
        previous.senderId != message.senderId ||
        message.timestamp.difference(previous.timestamp) > groupingWindow;
    entries.add(MessageEntry(message, startsGroup: startsGroup));
    previous = message;
  }
  return entries;
}

DateTime _dayOf(DateTime value) => DateTime(value.year, value.month, value.day);

bool _sameDay(Message a, Message b) =>
    _dayOf(a.timestamp) == _dayOf(b.timestamp);
