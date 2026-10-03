import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';

abstract interface class AuthRepository {
  /// Autentica no homeserver e persiste a sessão de forma segura.
  Future<Result<Session>> login(LoginCredentials credentials);

  /// Restaura a sessão salva. Falha com `NoSessionFailure` quando não há
  /// sessão e com `SessionExpiredFailure` quando o token não é mais válido.
  Future<Result<Session>> restoreSession();

  /// Invalida o token no servidor e apaga todos os dados locais da sessão.
  Future<Result<void>> logout();
}
