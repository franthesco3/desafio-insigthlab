import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/features/chat/domain/entities/message.dart';
import 'package:matrix_desktop/features/chat/presentation/timeline_entries.dart';

Message message(String id, String sender, DateTime timestamp) => Message(
  id: id,
  senderId: sender,
  senderName: sender,
  content: TextContent(id),
  timestamp: timestamp,
  isOwn: false,
);

void main() {
  test('sem mensagens não gera itens', () {
    expect(buildTimelineEntries(const []), isEmpty);
  });

  test('agrupa mensagens seguidas do mesmo autor', () {
    final a1 = message('1', '@a', DateTime(2026, 10, 3, 10));
    final a2 = message('2', '@a', DateTime(2026, 10, 3, 10, 2));
    final b1 = message('3', '@b', DateTime(2026, 10, 3, 10, 3));

    expect(buildTimelineEntries([a1, a2, b1]), [
      DayDivider(DateTime(2026, 10, 3)),
      MessageEntry(a1, startsGroup: true),
      MessageEntry(a2, startsGroup: false),
      MessageEntry(b1, startsGroup: true),
    ]);
  });

  test('intervalo longo inicia novo grupo do mesmo autor', () {
    final first = message('1', '@a', DateTime(2026, 10, 3, 10));
    final later = message('2', '@a', DateTime(2026, 10, 3, 10, 6));

    final entries = buildTimelineEntries([first, later]);

    expect(entries.last, MessageEntry(later, startsGroup: true));
  });

  test('insere divisor a cada novo dia', () {
    final night = message('1', '@a', DateTime(2026, 10, 2, 23, 58));
    final morning = message('2', '@a', DateTime(2026, 10, 3, 0, 1));

    expect(buildTimelineEntries([night, morning]), [
      DayDivider(DateTime(2026, 10, 2)),
      MessageEntry(night, startsGroup: true),
      DayDivider(DateTime(2026, 10, 3)),
      MessageEntry(morning, startsGroup: true),
    ]);
  });
}
