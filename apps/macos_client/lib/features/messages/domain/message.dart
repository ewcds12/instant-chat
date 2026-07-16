import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.clientMessageId,
    required this.sequence,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final PublicUser sender;
  final String clientMessageId;
  final String sequence;
  final String body;
  final DateTime createdAt;

  factory Message.fromJson(Map<String, Object?> json) {
    final senderValue = json['sender'];
    if (senderValue is! Map<Object?, Object?>) {
      throw const FormatException('sender must be a JSON object');
    }
    return Message(
      id: requiredString(json, 'id'),
      conversationId: requiredString(json, 'conversation_id'),
      sender: PublicUser.fromJson(_stringKeyed(senderValue)),
      clientMessageId: requiredString(json, 'client_message_id'),
      sequence: requiredString(json, 'sequence'),
      body: requiredString(json, 'body'),
      createdAt: requiredDateTime(json, 'created_at'),
    );
  }
}

Map<String, Object?> _stringKeyed(Map<Object?, Object?> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key case final String key) {
      result[key] = entry.value;
    } else {
      throw const FormatException('JSON object keys must be strings');
    }
  }
  return result;
}
