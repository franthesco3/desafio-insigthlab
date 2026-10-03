import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/utils/app_logger.dart';

void main() {
  group('redactSensitive', () {
    test('oculta tokens do Synapse e cabeçalhos Bearer', () {
      expect(
        redactSensitive('falhou com syt_YWxpY2U_abcDEF_123 no servidor'),
        'falhou com [REDACTED] no servidor',
      );
      expect(
        redactSensitive('Authorization: Bearer abc.def-ghi'),
        'Authorization: [REDACTED]',
      );
    });

    test('oculta valores de chaves sensíveis em JSON e query strings', () {
      expect(
        redactSensitive('{"access_token": "segredo", "user_id": "@a:b"}'),
        '{"access_token": [REDACTED], "user_id": "@a:b"}',
      );
      expect(
        redactSensitive('/sync?access_token=segredo&since=s1'),
        '/sync?access_token=[REDACTED]&since=s1',
      );
      expect(
        redactSensitive('LoginParams { password: hunter2 }'),
        'LoginParams { password: [REDACTED] }',
      );
    });

    test('mantém textos sem dados sensíveis', () {
      const message = 'NativeException(network: connection refused)';
      expect(redactSensitive(message), message);
    });
  });
}
