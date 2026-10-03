import 'package:get/get.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';

/// Sessão ativa compartilhada entre as telas.
class SessionService extends GetxService {
  final current = Rxn<Session>();

  bool get isAuthenticated => current.value != null;

  void start(Session session) => current.value = session;

  void end() => current.value = null;
}
