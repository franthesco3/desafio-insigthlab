import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/app/middlewares/auth_guard.dart';
import 'package:matrix_desktop/app/routes/app_routes.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

import '../mocks/auth_mocks.dart';

void main() {
  test('redireciona para o login sem sessão ativa', () {
    final guard = AuthGuard(SessionService.new);

    expect(guard.redirect(AppRoutes.home)?.name, AppRoutes.login);
  });

  test('permite a rota com sessão ativa', () {
    final sessionService = SessionService()..start(testSession);
    final guard = AuthGuard(() => sessionService);

    expect(guard.redirect(AppRoutes.home), isNull);
  });
}
