import 'package:equatable/equatable.dart';

/// Resumo de uma sala para exibição na lista.
final class Room extends Equatable {
  const Room({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastMessagePreview,
    this.lastActivity,
    this.unreadCount = 0,
    this.isEncrypted = false,
  });

  /// Matrix room ID, ex.: `!abc123:matrix.org`.
  final String id;
  final String name;
  final Uri? avatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastActivity;
  final int unreadCount;
  final bool isEncrypted;

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    lastMessagePreview,
    lastActivity,
    unreadCount,
    isEncrypted,
  ];
}
