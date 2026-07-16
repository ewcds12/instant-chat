class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;

  factory AuthUser.fromJson(Map<String, Object?> json) {
    return AuthUser(
      id: _requiredString(json, 'id'),
      username: _requiredString(json, 'username'),
      displayName: _requiredString(json, 'display_name'),
      createdAt: _requiredDateTime(json, 'created_at'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
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

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key must be an RFC 3339 timestamp');
  }
  return parsed;
}
