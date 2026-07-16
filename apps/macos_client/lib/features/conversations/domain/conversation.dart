import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.peer,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kind;
  final PublicUser peer;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    if (kind != 'direct') {
      throw const FormatException('kind must be direct');
    }
    return Conversation(
      id: requiredString(json, 'id'),
      kind: kind,
      peer: PublicUser.fromJson(peerJson),
      createdAt: requiredDateTime(json, 'created_at'),
      updatedAt: requiredDateTime(json, 'updated_at'),
    );
  }
}
