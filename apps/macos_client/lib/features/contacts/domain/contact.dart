import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class Contact {
  const Contact({
    required this.relationshipId,
    required this.user,
    this.remark = '',
    required this.connectedAt,
  });

  final String relationshipId;
  final PublicUser user;
  final String remark;
  final DateTime connectedAt;

  String get displayName => remark.isEmpty ? user.displayName : remark;

  factory Contact.fromJson(Map<String, Object?> json) {
    final userValue = json['user'];
    if (userValue is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    final remarkValue = json['remark'];
    if (remarkValue is! String) {
      throw const FormatException('remark must be a string');
    }
    return Contact(
      relationshipId: requiredString(json, 'relationship_id'),
      user: PublicUser.fromJson(_stringKeyed(userValue)),
      remark: remarkValue,
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
