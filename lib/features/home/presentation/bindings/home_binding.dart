import 'package:get/get.dart';
import 'package:matrix_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:matrix_desktop/features/chat/data/datasources/chat_native_datasource.dart';
import 'package:matrix_desktop/features/chat/data/repositories/message_repository_impl.dart';
import 'package:matrix_desktop/features/chat/domain/repositories/message_repository.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/load_older_messages_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/mark_room_as_read_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/retry_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:matrix_desktop/features/chat/domain/usecases/watch_timeline_usecase.dart';
import 'package:matrix_desktop/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:matrix_desktop/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:matrix_desktop/features/rooms/data/datasources/rooms_native_datasource.dart';
import 'package:matrix_desktop/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:matrix_desktop/features/rooms/domain/repositories/room_repository.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_rooms_usecase.dart';
import 'package:matrix_desktop/features/rooms/domain/usecases/watch_sync_status_usecase.dart';
import 'package:matrix_desktop/features/rooms/presentation/viewmodels/rooms_viewmodel.dart';

/// Dependências da área autenticada. Vivem enquanto a rota `/home` existir.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut<RoomRepository>(
        () => const RoomRepositoryImpl(FrbRoomsNativeDataSource()),
      )
      ..lazyPut<MessageRepository>(
        () => const MessageRepositoryImpl(FrbChatNativeDataSource()),
      )
      ..lazyPut(
        () => HomeViewModel(
          logout: LogoutUseCase(Get.find()),
          sessionService: Get.find(),
          navigator: Get.find(),
        ),
      )
      ..lazyPut(
        () => RoomsViewModel(
          watchRooms: WatchRoomsUseCase(Get.find()),
          watchSyncStatus: WatchSyncStatusUseCase(Get.find()),
        ),
      )
      ..lazyPut(
        () => ChatViewModel(
          watchTimeline: WatchTimelineUseCase(Get.find()),
          loadOlderMessages: LoadOlderMessagesUseCase(Get.find()),
          sendMessage: SendMessageUseCase(Get.find()),
          retryMessage: RetryMessageUseCase(Get.find()),
          markRoomAsRead: MarkRoomAsReadUseCase(Get.find()),
        ),
      );
  }
}
