import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/errors/failure.dart';
import 'package:matrix_desktop/core/native/bridge/api/rooms.dart';
import 'package:matrix_desktop/core/native/native_exception.dart';
import 'package:matrix_desktop/core/result/result.dart';
import 'package:matrix_desktop/features/rooms/data/datasources/rooms_native_datasource.dart';
import 'package:matrix_desktop/features/rooms/data/mappers/room_mapper.dart';
import 'package:matrix_desktop/features/rooms/data/repositories/room_repository_impl.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/room.dart';
import 'package:matrix_desktop/features/rooms/domain/entities/sync_status.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomsNativeDataSource extends Mock implements RoomsNativeDataSource {}

void main() {
  late MockRoomsNativeDataSource native;
  late RoomRepositoryImpl repository;

  setUp(() {
    native = MockRoomsNativeDataSource();
    repository = RoomRepositoryImpl(native);
  });

  group('watchRooms', () {
    test('emite Ok com as salas e Err em vez de erro de stream', () async {
      const room = Room(id: '!a:matrix.org', name: 'Geral');
      final controller = StreamController<List<Room>>();
      when(native.watchRooms).thenAnswer((_) => controller.stream);

      final expectation = expectLater(
        repository.watchRooms(),
        emitsInOrder([
          isA<Ok<List<Room>>>().having((r) => r.value, 'value', [room]),
          isA<Err<List<Room>>>().having(
            (r) => r.failure,
            'failure',
            isA<NetworkFailure>(),
          ),
          emitsDone,
        ]),
      );

      controller
        ..add([room])
        ..addError(const NativeException(NativeErrorKind.network));
      await controller.close();
      await expectation;
    });
  });

  group('watchSyncStatus', () {
    test('converte erro do stream em SyncStatus.error', () {
      when(native.watchSyncStatus).thenAnswer(
        (_) => Stream.fromIterable([
          SyncStatus.syncing,
        ]).followedBy(Stream.error(Exception('falha'))),
      );

      expect(
        repository.watchSyncStatus(),
        emitsInOrder([SyncStatus.syncing, SyncStatus.error, emitsDone]),
      );
    });
  });

  group('mappers', () {
    test('RoomSummaryDto vira Room com data local', () {
      final timestamp = DateTime(2026, 10, 3, 12).millisecondsSinceEpoch;
      final dto = RoomSummaryDto(
        roomId: '!a:matrix.org',
        name: 'Geral',
        lastMessagePreview: 'oi',
        lastActivityMs: timestamp,
        unreadCount: 2,
        isEncrypted: true,
      );

      expect(
        dto.toEntity(),
        Room(
          id: '!a:matrix.org',
          name: 'Geral',
          lastMessagePreview: 'oi',
          lastActivity: DateTime(2026, 10, 3, 12),
          unreadCount: 2,
          isEncrypted: true,
        ),
      );
    });

    test('cada SyncStateDto tem um SyncStatus', () {
      expect(
        SyncStateDto.values.map((s) => s.toEntity()),
        SyncStatus.values,
      );
    });
  });
}

extension<T> on Stream<T> {
  Stream<T> followedBy(Stream<T> next) async* {
    yield* this;
    yield* next;
  }
}
