import 'package:instant_chat/features/auth/domain/auth_user.dart';

class PublicUser {
  const PublicUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;

  factory PublicUser.fromJson(Map<String, Object?> json) {
    return PublicUser(
      id: requiredString(json, 'id'),
      username: requiredString(json, 'username'),
      displayName: requiredString(json, 'display_name'),
      createdAt: requiredDateTime(json, 'created_at'),
    );
  }

  factory PublicUser.fromAuthUser(AuthUser user) {
    return PublicUser(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      createdAt: user.createdAt,
    );
  }
}
