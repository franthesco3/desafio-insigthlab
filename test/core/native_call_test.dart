import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/native/native_call.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';

void main() {
  group('parseStreamError', () {
    test('reconstrói o tipo e o detalhe codificados pelo Rust', () {
      final error = parseStreamError('matrix_error:RoomNotFound:!x:matrix.org');

      expect(error.kind, NativeErrorKind.roomNotFound);
      expect(error.message, '!x:matrix.org');
    });

    test('formato desconhecido vira unknown com a mensagem original', () {
      expect(parseStreamError('panic').kind, NativeErrorKind.unknown);
      expect(
        parseStreamError('matrix_error:Inexistente:x').kind,
        NativeErrorKind.unknown,
      );
    });
  });

  test('guardNativeStream converte AnyhowException em NativeException', () {
    final stream = guardNativeStream(
      Stream<int>.error(AnyhowException('matrix_error:NotLoggedIn:no session')),
    );

    expect(
      stream,
      emitsError(
        isA<NativeException>().having(
          (e) => e.kind,
          'kind',
          NativeErrorKind.notLoggedIn,
        ),
      ),
    );
  });
}
