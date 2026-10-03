import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix_desktop/core/navigation/app_navigator.dart';
import 'package:matrix_desktop/core/storage/app_directories.dart';
import 'package:matrix_desktop/features/auth/data/datasources/auth_native_datasource.dart';
import 'package:matrix_desktop/features/auth/data/datasources/session_storage.dart';
import 'package:matrix_desktop/features/auth/data/models/stored_session.dart';
import 'package:matrix_desktop/features/auth/domain/entities/login_credentials.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNativeDataSource extends Mock implements AuthNativeDataSource {}

class MockSessionStorage extends Mock implements SessionStorage {}

class MockAppDirectories extends Mock implements AppDirectories {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAppNavigator extends Mock implements AppNavigator {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

const testStoredSession = StoredSession(
  userId: '@alice:matrix.org',
  deviceId: 'DEVICE',
  accessToken: 'secret-access-token',
  refreshToken: 'secret-refresh-token',
  homeserverUrl: 'https://matrix-client.matrix.org/',
);

final testSession = Session(
  userId: '@alice:matrix.org',
  deviceId: 'DEVICE',
  homeserver: Uri.parse('https://matrix-client.matrix.org/'),
);

/// Fallback para `any()` em `AuthRepository.login`.
final fallbackCredentials = LoginCredentials(
  homeserver: Uri(),
  username: '',
  password: '',
);
