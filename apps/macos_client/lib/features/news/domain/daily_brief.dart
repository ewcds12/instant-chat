import 'package:instant_chat/core/network/api_response.dart';

class DailyBrief {
  const DailyBrief({required this.items, required this.updatedAt});

  factory DailyBrief.fromJson(Map<String, Object?> json) {
    final updatedAt = DateTime.tryParse(_requiredString(json, 'updated_at'));
    if (updatedAt == null) {
      throw const FormatException('updated_at must be an RFC 3339 timestamp');
    }
    return DailyBrief(
      items: requiredList(json, 'items')
          .map((value) => DailyNewsItem.fromJson(_requiredObject(value)))
          .toList(growable: false),
      updatedAt: updatedAt,
    );
  }

  final List<DailyNewsItem> items;
  final DateTime updatedAt;
}

class DailyNewsItem {
  const DailyNewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
  });

  factory DailyNewsItem.fromJson(Map<String, Object?> json) {
    final url = Uri.tryParse(_requiredString(json, 'url'));
    if (url == null || (url.scheme != 'http' && url.scheme != 'https')) {
      throw const FormatException('url must be a web URL');
    }
    return DailyNewsItem(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      summary: _requiredString(json, 'summary'),
      source: _requiredString(json, 'source'),
      url: url,
    );
  }

  final String id;
  final String title;
  final String summary;
  final String source;
  final Uri url;
}

Map<String, Object?> _requiredObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('News item must be a JSON object');
  }
  return stringKeyedObject(value);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}
