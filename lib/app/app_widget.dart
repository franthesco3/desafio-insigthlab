import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/app/bindings/initial_binding.dart';
import 'package:matrix_desktop/app/routes/app_pages.dart';
import 'package:matrix_desktop/app/routes/app_routes.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Matrix Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
