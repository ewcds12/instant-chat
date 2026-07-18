import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.peer,
    required this.createdAt,
    required this.updatedAt,
    required this.unreadCount,
  });

  final String id;
  final String kind;
  final PublicUser peer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, Object?> json) {
    final peerValue = json['peer'];
    if (peerValue is! Map<Object?, Object?>) {
      throw const FormatException('peer must be a JSON object');
    }
    final peerJson = <String, Object?>{};
    for (final entry in peerValue.entries) {
      if (entry.key case final String key) {
        peerJson[key] = entry.value;
      } else {
        throw const FormatException('JSON object keys must be strings');
      }
    }
    final kind = requiredString(json, 'kind');
    final unreadCount = json['unread_count'];
    if (kind != 'direct') {
      throw const FormatException('kind must be direct');
    }
    if (unreadCount is! int || unreadCount < 0) {
      throw const FormatException(
        'unread_count must be a non-negative integer',
      );
    }
    return Conversation(
      id: requiredString(json, 'id'),
      kind: kind,
      peer: PublicUser.fromJson(peerJson),
      createdAt: requiredDateTime(json, 'created_at'),
      updatedAt: requiredDateTime(json, 'updated_at'),
      unreadCount: unreadCount,
    );
  }

  Conversation copyWith({DateTime? updatedAt, int? unreadCount}) {
    return Conversation(
      id: id,
      kind: kind,
      peer: peer,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
