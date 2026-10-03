import 'package:flutter/widgets.dart';
import 'package:matrix_desktop/app/app_widget.dart';
import 'package:matrix_desktop/core/native/native_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NativeBridge.init();
  runApp(const AppWidget());
}
