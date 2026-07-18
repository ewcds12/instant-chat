class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
    this.gender,
    this.region,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;
  final String? gender;
  final String? region;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, Object?> json) {
    return AuthUser(
      id: _requiredString(json, 'id'),
      username: _requiredString(json, 'username'),
      displayName: _requiredString(json, 'display_name'),
      createdAt: _requiredDateTime(json, 'created_at'),
      gender: _nullableString(json, 'gender'),
      region: _nullableString(json, 'region'),
      avatarUrl: _nullableString(json, 'avatar_url'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'created_at': createdAt.toUtc().toIso8601String(),
    'gender': gender,
    'region': region,
    'avatar_url': avatarUrl,
  };

  AuthUser copyWith({
    String? username,
    String? displayName,
    String? gender,
    String? region,
    String? avatarUrl,
    bool clearGender = false,
    bool clearRegion = false,
    bool clearAvatarUrl = false,
  }) {
    return AuthUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      gender: clearGender ? null : gender ?? this.gender,
      region: clearRegion ? null : region ?? this.region,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
    );
  }
}

String requiredString(Map<String, Object?> json, String key) {
  return _requiredString(json, key);
}

DateTime requiredDateTime(Map<String, Object?> json, String key) {
  return _requiredDateTime(json, key);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
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

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an RFC 3339 timestamp');
  }
  return parsed;
}
