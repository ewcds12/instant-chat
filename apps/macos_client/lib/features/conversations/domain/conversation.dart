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
    this.lastMessage,
  });

  final String id;
  final String kind;
  final PublicUser peer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final ConversationLastMessage? lastMessage;

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
      lastMessage: ConversationLastMessage.fromJsonOrNull(json['last_message']),
    );
  }

  Conversation copyWith({
    DateTime? updatedAt,
    int? unreadCount,
    ConversationLastMessage? lastMessage,
  }) {
    return Conversation(
      id: id,
      kind: kind,
      peer: peer,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class ConversationLastMessage {
  const ConversationLastMessage({
    required this.sequence,
    required this.kind,
    required this.body,
    required this.fileName,
  });

  final String sequence;
  final String kind;
  final String body;
  final String fileName;

  static ConversationLastMessage? fromJsonOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('last_message must be a JSON object or null');
    }
    final json = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key case final String key) {
        json[key] = entry.value;
      } else {
        throw const FormatException('JSON object keys must be strings');
      }
    }
    final kind = requiredString(json, 'kind');
    final fileName = json['file_name'];
    if (kind != 'text' && kind != 'image' && kind != 'file') {
      throw const FormatException('last_message kind is not supported');
    }
    if (fileName is! String) {
      throw const FormatException('last_message file_name must be a string');
    }
    return ConversationLastMessage(
      sequence: requiredString(json, 'sequence'),
      kind: kind,
      body: _requiredMessageBody(json),
      fileName: fileName,
    );
  }
}

String _requiredMessageBody(Map<String, Object?> json) {
  final body = json['body'];
  if (body is! String) {
    throw const FormatException('last_message body must be a string');
  }
  return body;
}
