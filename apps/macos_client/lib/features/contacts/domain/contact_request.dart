import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class ContactRequest {
  const ContactRequest({
    required this.id,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final PublicUser user;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ContactRequest.fromJson(Map<String, Object?> json) {
    final userValue = json['user'];
    if (userValue is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    final userJson = <String, Object?>{};
    for (final entry in userValue.entries) {
      if (entry.key case final String key) {
        userJson[key] = entry.value;
      } else {
        throw const FormatException('JSON object keys must be strings');
      }
    }
    return ContactRequest(
      id: requiredString(json, 'id'),
      user: PublicUser.fromJson(userJson),
      createdAt: requiredDateTime(json, 'created_at'),
      updatedAt: requiredDateTime(json, 'updated_at'),
    );
  }
}

class ContactRequestLists {
  const ContactRequestLists({required this.incoming, required this.outgoing});

  final List<ContactRequest> incoming;
  final List<ContactRequest> outgoing;
}
