import 'package:get/get.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/splash_viewmodel.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SplashViewModel(
        restoreSession: RestoreSessionUseCase(Get.find()),
        sessionService: Get.find(),
        navigator: Get.find(),
      ),
    );
  }
}
