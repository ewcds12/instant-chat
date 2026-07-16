import 'package:instant_chat/features/auth/domain/auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  final AuthUser user;
  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final userValue = json['user'];
    if (userValue is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    return AuthSession(
      user: AuthUser.fromJson(stringKeyedMap(userValue)),
      accessToken: requiredString(json, 'access_token'),
      accessExpiresAt: requiredDateTime(json, 'access_expires_at'),
      refreshToken: requiredString(json, 'refresh_token'),
      refreshExpiresAt: requiredDateTime(json, 'refresh_expires_at'),
    );
  }

  AuthSession copyWith({AuthUser? user}) {
    return AuthSession(
      user: user ?? this.user,
      accessToken: accessToken,
      accessExpiresAt: accessExpiresAt,
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiresAt,
    );
  }

  Map<String, Object?> toJson() => {
    'user': user.toJson(),
    'access_token': accessToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'refresh_token': refreshToken,
    'refresh_expires_at': refreshExpiresAt.toUtc().toIso8601String(),
  };
}

Map<String, Object?> stringKeyedMap(Map<Object?, Object?> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw const FormatException('JSON object keys must be strings');
    }
    result[key] = entry.value;
  }
  return result;
}
