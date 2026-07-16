import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Contact {
  const Contact({
    required this.relationshipId,
    required this.user,
    required this.connectedAt,
  });

  final String relationshipId;
  final PublicUser user;
  final DateTime connectedAt;

  factory Contact.fromJson(Map<String, Object?> json) {
    final userValue = json['user'];
    if (userValue is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    return Contact(
      relationshipId: requiredString(json, 'relationship_id'),
      user: PublicUser.fromJson(_stringKeyed(userValue)),
      connectedAt: requiredDateTime(json, 'connected_at'),
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
