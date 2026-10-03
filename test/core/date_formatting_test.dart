import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/ui/date_formatting.dart';

void main() {
  final now = DateTime(2026, 10, 3, 15, 30);

  test('hoje mostra a hora', () {
    expect(
      formatShortTimestamp(DateTime(2026, 10, 3, 9, 5), now: now),
      '09:05',
    );
  });

  test('ontem mostra "Ontem", inclusive na virada do mês', () {
    expect(formatShortTimestamp(DateTime(2026, 10, 2, 23), now: now), 'Ontem');
    expect(
      formatShortTimestamp(DateTime(2026, 9, 30), now: DateTime(2026, 10)),
      'Ontem',
    );
  });

  test('mesmo ano mostra dia/mês; anos anteriores incluem o ano', () {
    expect(formatShortTimestamp(DateTime(2026, 3, 7), now: now), '07/03');
    expect(formatShortTimestamp(DateTime(2025, 12, 25), now: now), '25/12/25');
  });

  test('formatFullTimestamp inclui data e hora', () {
    expect(formatFullTimestamp(DateTime(2026, 3, 7, 9, 5)), '07/03/2026 09:05');
  });

  test('formatTime usa HH:mm', () {
    expect(formatTime(DateTime(2026, 10, 3, 7, 4)), '07:04');
  });

  test('formatDayLabel mostra Hoje, Ontem ou a data completa', () {
    expect(formatDayLabel(DateTime(2026, 10, 3, 1), now: now), 'Hoje');
    expect(formatDayLabel(DateTime(2026, 10, 2, 23), now: now), 'Ontem');
    expect(formatDayLabel(DateTime(2026, 3, 7), now: now), '07/03/2026');
  });
}
