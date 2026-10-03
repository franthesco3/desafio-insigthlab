/// Data curta para listas: hora se for hoje, "Ontem", dia/mês no mesmo ano
/// ou dia/mês/ano.
String formatShortTimestamp(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  switch (_relativeDay(value, reference)) {
    case _RelativeDay.today:
      return formatTime(value);
    case _RelativeDay.yesterday:
      return 'Ontem';
    case _RelativeDay.earlier:
      final dayMonth = '${_twoDigits(value.day)}/${_twoDigits(value.month)}';
      return value.year == reference.year
          ? dayMonth
          : '$dayMonth/${_twoDigits(value.year % 100)}';
  }
}

/// Hora no formato `HH:mm`.
String formatTime(DateTime value) =>
    '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

/// Data e hora completas (`dd/MM/yyyy HH:mm`), para dicas de contexto.
String formatFullTimestamp(DateTime value) =>
    '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year} '
    '${formatTime(value)}';

/// Rótulo do divisor de dia na conversa: "Hoje", "Ontem" ou a data completa.
String formatDayLabel(DateTime value, {DateTime? now}) =>
    switch (_relativeDay(value, now ?? DateTime.now())) {
      _RelativeDay.today => 'Hoje',
      _RelativeDay.yesterday => 'Ontem',
      _RelativeDay.earlier =>
        '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}',
    };

enum _RelativeDay { today, yesterday, earlier }

_RelativeDay _relativeDay(DateTime value, DateTime reference) {
  final day = DateTime(value.year, value.month, value.day);
  if (day == DateTime(reference.year, reference.month, reference.day)) {
    return _RelativeDay.today;
  }
  // Construído pelo calendário (não por Duration) para não errar em DST.
  final yesterday = DateTime(
    reference.year,
    reference.month,
    reference.day - 1,
  );
  return day == yesterday ? _RelativeDay.yesterday : _RelativeDay.earlier;
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');
