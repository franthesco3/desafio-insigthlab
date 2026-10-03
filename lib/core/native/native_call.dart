import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:matrix_desktop/core/native/bridge/api/error.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';

/// Executa uma chamada ao Rust convertendo o erro gerado pelo FRB em
/// [NativeException]. Data sources devem envolver toda chamada nativa nele.
Future<T> guardNative<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on MatrixError catch (error) {
    throw error.toNativeException();
  }
}

/// Equivalente a [guardNative] para streams vindos do Rust.
///
/// O FRB só entrega erros de stream como [AnyhowException]; o Rust codifica
/// o `MatrixErrorKind` na mensagem (`MatrixError::into_stream_error`).
Stream<T> guardNativeStream<T>(Stream<T> stream) {
  return stream.transform(
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) => sink.addError(
        switch (error) {
          MatrixError() => error.toNativeException(),
          AnyhowException(:final message) => parseStreamError(message),
          _ => error,
        },
        stackTrace,
      ),
    ),
  );
}

/// Precisa ser igual ao `STREAM_ERROR_PREFIX` de `error_mapping.rs`.
const _streamErrorPrefix = 'matrix_error:';

/// Reconstrói a [NativeException] de uma mensagem
/// `matrix_error:<Kind>:<detalhe>`. Formatos desconhecidos viram `unknown`.
NativeException parseStreamError(String message) {
  if (!message.startsWith(_streamErrorPrefix)) {
    return NativeException(NativeErrorKind.unknown, message);
  }
  final rest = message.substring(_streamErrorPrefix.length);
  final separator = rest.indexOf(':');
  if (separator <= 0) return NativeException(NativeErrorKind.unknown, message);

  // Rust usa PascalCase (`RoomNotFound`); o enum gerado, camelCase.
  final rustName = rest.substring(0, separator);
  final dartName = rustName[0].toLowerCase() + rustName.substring(1);
  final kind = MatrixErrorKind.values.asNameMap()[dartName];
  return NativeException(
    kind == null ? NativeErrorKind.unknown : _kindOf(kind),
    rest.substring(separator + 1),
  );
}

extension on MatrixError {
  NativeException toNativeException() =>
      NativeException(_kindOf(kind), message);
}

NativeErrorKind _kindOf(MatrixErrorKind kind) => switch (kind) {
  MatrixErrorKind.network => NativeErrorKind.network,
  MatrixErrorKind.homeserverUnreachable =>
    NativeErrorKind.homeserverUnreachable,
  MatrixErrorKind.invalidCredentials => NativeErrorKind.invalidCredentials,
  MatrixErrorKind.sessionExpired => NativeErrorKind.sessionExpired,
  MatrixErrorKind.notLoggedIn => NativeErrorKind.notLoggedIn,
  MatrixErrorKind.roomNotFound => NativeErrorKind.roomNotFound,
  MatrixErrorKind.storage => NativeErrorKind.storage,
  MatrixErrorKind.unknown => NativeErrorKind.unknown,
};
