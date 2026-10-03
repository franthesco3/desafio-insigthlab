import 'package:matrix_desktop/core/errors/failure.dart';

/// Resultado explícito de uma operação que pode falhar.
///
/// Repositórios e casos de uso retornam [Result] em vez de lançar exceções,
/// o que obriga quem chama a tratar o erro (via `switch` exaustivo).
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}
