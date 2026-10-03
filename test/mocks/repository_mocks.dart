import 'package:matrix_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';
import 'package:matrix_desktop/features/rooms/domain/repositories/room_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockRoomRepository extends Mock implements RoomRepository {}

class MockMessageRepository extends Mock implements MessageRepository {}
