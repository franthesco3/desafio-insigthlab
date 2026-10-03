import 'package:matrix_desktop/core/native/bridge/frb_generated.dart';

/// Ponto único de inicialização da biblioteca Rust.
///
/// O restante do app não deve importar o código gerado em `bridge/`
/// diretamente; ele é acessado apenas pelos data sources.
abstract final class NativeBridge {
  static Future<void> init() => RustLib.init();
}
