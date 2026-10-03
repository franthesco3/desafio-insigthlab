import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';

void main() {
  test('cada tipo de erro nativo vira a Failure correspondente', () {
    final expected = <NativeErrorKind, Type>{
      NativeErrorKind.network: NetworkFailure,
      NativeErrorKind.homeserverUnreachable: HomeserverUnreachableFailure,
      NativeErrorKind.invalidCredentials: InvalidCredentialsFailure,
      NativeErrorKind.sessionExpired: SessionExpiredFailure,
      NativeErrorKind.notLoggedIn: SessionExpiredFailure,
      NativeErrorKind.roomNotFound: RoomNotFoundFailure,
      NativeErrorKind.storage: UnexpectedFailure,
      NativeErrorKind.unknown: UnexpectedFailure,
    };

    for (final kind in NativeErrorKind.values) {
      final failure = NativeException(kind, 'detalhe').toFailure();
      expect(failure.runtimeType, expected[kind], reason: '$kind');
      expect(failure.details, 'detalhe');
    }
  });
}
