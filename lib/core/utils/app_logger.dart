import 'dart:developer' as developer;

/// Logger central do app.
///
/// Toda mensagem passa por [redactSensitive] antes de ser escrita, e nada é
/// registrado em builds de release. Nunca registre conteúdo de mensagens.
abstract final class AppLogger {
  static const bool _enabled = !bool.fromEnvironment('dart.vm.product');

  static void warning(String message) => _log(message, level: 900);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  static void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    developer.log(
      redactSensitive(message),
      name: 'matrix_desktop',
      level: level,
      error: error == null ? null : redactSensitive(error.toString()),
      stackTrace: stackTrace,
    );
  }
}

const _redacted = '[REDACTED]';

final _sensitivePatterns = <RegExp>[
  // Tokens emitidos pelo Synapse (`syt_...`) e similares.
  RegExp(r'\bsy[a-z]_[A-Za-z0-9_\-]+'),
  RegExp(r'Bearer\s+[A-Za-z0-9._~+/\-]+=*', caseSensitive: false),
  // Pares chave/valor em JSON, query strings ou `Debug` do Rust.
  RegExp(
    r'''("?(?:access_token|refresh_token|password|passphrase)"?\s*[:=]\s*)("[^"]*"|[^\s,&}]+)''',
    caseSensitive: false,
  ),
];

/// Substitui tokens, senhas e passphrases por `[REDACTED]`.
String redactSensitive(String input) {
  var output = input;
  for (final pattern in _sensitivePatterns) {
    output = output.replaceAllMapped(
      pattern,
      (match) =>
          match.groupCount >= 2 ? '${match.group(1)}$_redacted' : _redacted,
    );
  }
  return output;
}
