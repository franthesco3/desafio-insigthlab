import 'package:matrix_desktop/core/errors/failure.dart';

/// Estado de uma operação exibida na tela.
sealed class ViewState<T> {
  const ViewState();
}

final class Idle<T> extends ViewState<T> {
  const Idle();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Success<T> extends ViewState<T> {
  const Success(this.data);

  final T data;
}

final class Failed<T> extends ViewState<T> {
  const Failed(this.failure);

  final Failure failure;
}
