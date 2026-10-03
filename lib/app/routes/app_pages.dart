import 'package:get/get.dart';
import 'package:matrix_desktop/app/middlewares/auth_guard.dart';
import 'package:matrix_desktop/app/routes/app_routes.dart';
import 'package:matrix_desktop/features/auth/presentation/bindings/login_binding.dart';
import 'package:matrix_desktop/features/auth/presentation/bindings/splash_binding.dart';
import 'package:matrix_desktop/features/auth/presentation/views/login_view.dart';
import 'package:matrix_desktop/features/auth/presentation/views/splash_view.dart';
import 'package:matrix_desktop/features/home/presentation/bindings/home_binding.dart';
import 'package:matrix_desktop/features/home/presentation/views/home_view.dart';

abstract final class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: SplashView.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginView.new,
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: HomeView.new,
      binding: HomeBinding(),
      middlewares: [AuthGuard(Get.find)],
      transition: Transition.fadeIn,
    ),
  ];
}
