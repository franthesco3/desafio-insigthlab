import 'dart:async';

import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/core/utils/app_logger.dart';

/// Executa [action] convertendo qualquer exceção em [Err], para que
/// repositórios nunca lancem para as camadas de cima.
Future<Result<T>> guardResult<T>(Future<Result<T>> Function() action) async {
  try {
    return await action();
  } on Object catch (error, stackTrace) {
    return Err(_toFailure(error, stackTrace));
  }
}

extension NativeResultStream<T> on Stream<T> {
  /// Converte dados em [Ok] e erros em [Err], para que repositórios exponham
  /// streams que nunca emitem erro (mesma regra dos `Future<Result>`).
  Stream<Result<T>> asResults() {
    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(Ok(data)),
        handleError: (error, stackTrace, sink) =>
            sink.add(Err(_toFailure(error, stackTrace))),
      ),
    );
  }
}

Failure _toFailure(Object error, StackTrace stackTrace) {
  if (error is NativeException) {
    AppLogger.warning('$error');
    return error.toFailure();
  }
  AppLogger.error('Erro inesperado', error: error, stackTrace: stackTrace);
  return UnexpectedFailure(error.runtimeType.toString());
}
