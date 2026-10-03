import 'package:equatable/equatable.dart';

/// Credenciais já validadas e normalizadas pelo `LoginUseCase`.
final class LoginCredentials extends Equatable {
  const LoginCredentials({
    required this.homeserver,
    required this.username,
    required this.password,
  });

  final Uri homeserver;
  final String username;
  final String password;

  @override
  List<Object?> get props => [homeserver, username, password];

  // Nunca expor a senha em logs ou mensagens de erro.
  @override
  String toString() => 'LoginCredentials($username @ $homeserver)';
}
