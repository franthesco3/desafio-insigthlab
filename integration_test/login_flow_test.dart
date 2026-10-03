import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matrix_desktop/app/app_widget.dart';
import 'package:matrix_desktop/core/native/native_bridge.dart';

/// Fluxo real contra o matrix.org (requer internet): Splash sem sessão →
/// Login → senha incorreta → mensagem de erro.
///
/// Exercita, no app de verdade: Keychain (passphrase do banco), permissão de
/// rede do sandbox, descoberta do homeserver no Rust e o mapeamento de erros
/// até a UI.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(NativeBridge.init);

  testWidgets('senha incorreta no matrix.org exibe erro amigável', (
    tester,
  ) async {
    await tester.pumpWidget(const AppWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login.submit')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login.username')),
      '@matrix-desktop-nonexistent-user:matrix.org',
    );
    await tester.enterText(
      find.byKey(const Key('login.password')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login.submit')));

    await _pumpUntilFound(tester, find.text('Usuário ou senha incorretos.'));
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timeout esperando por $finder');
}
