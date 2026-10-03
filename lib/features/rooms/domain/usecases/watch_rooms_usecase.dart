import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/repositories/room_repository.dart';

/// Observa as salas do usuário, ordenadas da atividade mais recente para a
/// mais antiga. Salas sem atividade conhecida vão para o fim, por nome.
class WatchRoomsUseCase {
  const WatchRoomsUseCase(this._repository);

  final RoomRepository _repository;

  Stream<Result<List<Room>>> call() {
    return _repository.watchRooms().map(
      (result) => switch (result) {
        Ok(:final value) => Ok(_sorted(value)),
        Err() => result,
      },
    );
  }

  static List<Room> _sorted(List<Room> rooms) {
    return [...rooms]..sort(_byRecentActivity);
  }

  static int _byRecentActivity(Room a, Room b) {
    final activityA = a.lastActivity;
    final activityB = b.lastActivity;
    if (activityA == null && activityB == null) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
    if (activityA == null) return 1;
    if (activityB == null) return -1;
    return activityB.compareTo(activityA);
  }
}
