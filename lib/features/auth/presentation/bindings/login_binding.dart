import 'package:get/get.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:matrix_desktop/features/auth/presentation/viewmodels/login_viewmodel.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginViewModel(
        login: LoginUseCase(Get.find()),
        sessionService: Get.find(),
        navigator: Get.find(),
      ),
    );
  }
}
