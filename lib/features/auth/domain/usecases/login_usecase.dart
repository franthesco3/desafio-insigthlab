import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/repositories/auth_repository.dart';

/// Dados do formulário de login, como digitados pelo usuário.
typedef LoginParams = ({String homeserver, String username, String password});

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// HTTP sem TLS só é aceito para servidores locais de desenvolvimento
  /// (ex.: Synapse em Docker).
  static const _localHosts = {'localhost', '127.0.0.1', '::1'};

  Future<Result<Session>> call(LoginParams params) async {
    final Uri homeserver;
    switch (_parseHomeserver(params.homeserver)) {
      case Ok(:final value):
        homeserver = value;
      case Err(:final failure):
        return Err(failure);
    }

    final username = params.username.trim();
    if (username.isEmpty) {
      return const Err(ValidationFailure(ValidationError.emptyUsername));
    }
    if (params.password.isEmpty) {
      return const Err(ValidationFailure(ValidationError.emptyPassword));
    }

    return _repository.login(
      LoginCredentials(
        homeserver: homeserver,
        username: username,
        password: params.password,
      ),
    );
  }

  Result<Uri> _parseHomeserver(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return const Err(ValidationFailure(ValidationError.emptyHomeserver));
    }

    final withScheme = input.contains('://') ? input : 'https://$input';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || input.contains(' ')) {
      return const Err(ValidationFailure(ValidationError.invalidHomeserver));
    }

    return switch (uri.scheme) {
      'https' => Ok(uri),
      'http' when _localHosts.contains(uri.host) => Ok(uri),
      'http' => const Err(
        ValidationFailure(ValidationError.insecureHomeserver),
      ),
      _ => const Err(ValidationFailure(ValidationError.invalidHomeserver)),
    };
  }
}
