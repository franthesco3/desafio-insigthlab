import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class AppDirectories {
  /// Diretório do banco local (SQLite criptografado) do matrix-sdk.
  Future<String> matrixStorePath();
}

final class PlatformAppDirectories implements AppDirectories {
  const PlatformAppDirectories();

  @override
  Future<String> matrixStorePath() async {
    final support = await getApplicationSupportDirectory();
    return '${support.path}${Platform.pathSeparator}matrix_store';
  }
}
