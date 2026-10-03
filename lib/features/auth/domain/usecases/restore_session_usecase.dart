import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/auth/domain/entities/session.dart';
import 'package:matrix_desktop/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<Session>> call() => _repository.restoreSession();
}
