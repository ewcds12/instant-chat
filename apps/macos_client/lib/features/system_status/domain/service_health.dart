class ServiceHealth {
  const ServiceHealth({
    required this.status,
    required this.service,
    required this.database,
    required this.checkedAt,
  });

  final String status;
  final String service;
  final String database;
  final DateTime checkedAt;

  bool get isHealthy => status == 'healthy' && database == 'healthy';

  factory ServiceHealth.fromJson(Map<String, Object?> json) {
    final status = _requiredString(json, 'status');
    final service = _requiredString(json, 'service');
    final database = _requiredString(json, 'database');
    final checkedAtValue = _requiredString(json, 'checked_at');
    final checkedAt = DateTime.tryParse(checkedAtValue);
    if (checkedAt == null) {
      throw const FormatException('checked_at must be an RFC 3339 timestamp');
    }

    return ServiceHealth(
      status: status,
      service: service,
      database: database,
      checkedAt: checkedAt,
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}
