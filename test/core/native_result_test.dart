import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/native/native_result.dart';
import 'package:matrix_desktop/core/result/result.dart';

void main() {
  group('guardResult', () {
    test('repassa o resultado da ação', () async {
      final result = await guardResult(() async => const Ok(1));

      expect((result as Ok<int>).value, 1);
    });

    test('NativeException vira a Failure correspondente', () async {
      final result = await guardResult<int>(
        () => throw const NativeException(NativeErrorKind.network),
      );

      expect((result as Err).failure, isA<NetworkFailure>());
    });

    test('qualquer outro erro vira UnexpectedFailure', () async {
      final result = await guardResult<int>(() => throw StateError('x'));

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });
  });

  test('asResults transforma dados e erros em Result', () {
    final stream = Stream<int>.fromFutures([
      Future.value(1),
      Future.error(const NativeException(NativeErrorKind.roomNotFound)),
    ]).asResults();

    expect(
      stream,
      emitsInOrder([
        isA<Ok<int>>(),
        isA<Err<int>>().having(
          (r) => r.failure,
          'failure',
          isA<RoomNotFoundFailure>(),
        ),
        emitsDone,
      ]),
    );
  });
}
