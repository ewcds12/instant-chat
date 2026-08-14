import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/news/data/dio_daily_news_gateway.dart';

void main() {
  test('fetch parses the authenticated daily brief', () async {
    final adapter = _StubAdapter({
      'items': [
        {
          'id': '42',
          'title': 'Solar eclipse of August 12, 2026',
          'summary': 'A solar eclipse crosses Europe and Asia.',
          'source': 'Wikipedia Current Events',
          'url': 'https://en.wikipedia.org/wiki/Solar_eclipse',
        },
      ],
      'updated_at': '2026-08-14T08:30:00Z',
    });
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8080',
        validateStatus: (status) => status != null && status < 600,
      ),
    )..httpClientAdapter = adapter;

    final brief = await DioDailyNewsGateway(dio).fetch('access-token');

    expect(adapter.path, '/api/v1/news/daily');
    expect(adapter.authorization, 'Bearer access-token');
    expect(brief.items.single.id, '42');
    expect(brief.updatedAt, DateTime.utc(2026, 8, 14, 8, 30));
  });

  test('fetch rejects a malformed news URL', () async {
    final adapter = _StubAdapter({
      'items': [
        {
          'id': '42',
          'title': 'Headline',
          'summary': 'Summary',
          'source': 'Wikipedia Current Events',
          'url': 'file:///tmp/article',
        },
      ],
      'updated_at': '2026-08-14T08:30:00Z',
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080'))
      ..httpClientAdapter = adapter;

    await expectLater(
      DioDailyNewsGateway(dio).fetch('token'),
      throwsA(isA<FormatException>()),
    );
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Object body;
  String? path;
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    authorization = options.headers['Authorization'] as String?;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
