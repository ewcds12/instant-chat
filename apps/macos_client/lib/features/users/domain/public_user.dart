import 'package:instant_chat/features/auth/domain/auth_user.dart';

class PublicUser {
  const PublicUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;
  final String? avatarUrl;

  factory PublicUser.fromJson(Map<String, Object?> json) {
    return PublicUser(
      id: requiredString(json, 'id'),
      username: requiredString(json, 'username'),
      displayName: requiredString(json, 'display_name'),
      createdAt: requiredDateTime(json, 'created_at'),
      avatarUrl: _nullableString(json, 'avatar_url'),
    );
  }

  factory PublicUser.fromAuthUser(AuthUser user) {
    return PublicUser(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      createdAt: user.createdAt,
      avatarUrl: user.avatarUrl,
    );
  }

  PublicUser copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    return PublicUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
    );
  }
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string or null');
  }
  return value;
}
