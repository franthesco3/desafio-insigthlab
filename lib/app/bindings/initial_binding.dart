import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:matrix_desktop/app/routes/get_app_navigator.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';
import 'package:matrix_desktop/core/storage/app_directories.dart';
import 'package:matrix_desktop/features/auth/data/datasources/auth_native_datasource.dart';
import 'package:matrix_desktop/features/auth/data/datasources/session_storage.dart';
import 'package:matrix_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:matrix_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:matrix_desktop/features/auth/presentation/session_service.dart';

/// Composition root: dependências que vivem durante todo o app.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put<AppNavigator>(const GetAppNavigator(), permanent: true)
      ..put(SessionService(), permanent: true)
      ..put<AuthRepository>(
        AuthRepositoryImpl(
          native: const FrbAuthNativeDataSource(),
          storage: SecureSessionStorage(
            const FlutterSecureStorage(
              // Keychain clássico: dispensa provisioning profile/conta Apple
              // para rodar o app localmente.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            ),
          ),
          directories: const PlatformAppDirectories(),
        ),
        permanent: true,
      );
  }
}
