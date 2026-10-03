import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/app/routes/app_routes.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

/// Redireciona para o login rotas que exigem sessão ativa.
class AuthGuard extends GetMiddleware {
  /// Recebe uma fábrica para resolver o serviço só no momento da navegação.
  AuthGuard(this._sessionService);

  final SessionService Function() _sessionService;

  @override
  RouteSettings? redirect(String? route) {
    return _sessionService().isAuthenticated
        ? null
        : const RouteSettings(name: AppRoutes.login);
  }
}
