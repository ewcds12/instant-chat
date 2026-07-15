import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/system_status/data/dio_health_gateway.dart';

void main() {
  test('fetch parses a healthy response', () async {
    final adapter = StubAdapter(
      statusCode: 200,
      body: {
        'status': 'healthy',
        'service': 'instant-chat-api',
        'database': 'healthy',
        'checked_at': '2026-07-15T12:00:00Z',
      },
    );
    final dio = createDio(adapter);

    final health = await DioHealthGateway(dio).fetch();

    expect(adapter.requestedPath, '/api/v1/health');
    expect(health.isHealthy, isTrue);
    expect(health.checkedAt, DateTime.utc(2026, 7, 15, 12));
  });

  test('fetch accepts a degraded 503 response', () async {
    final adapter = StubAdapter(
      statusCode: 503,
      body: {
        'status': 'degraded',
        'service': 'instant-chat-api',
        'database': 'unavailable',
        'checked_at': '2026-07-15T12:00:00Z',
      },
    );

    final health = await DioHealthGateway(createDio(adapter)).fetch();

    expect(health.isHealthy, isFalse);
    expect(health.database, 'unavailable');
  });

  test('fetch rejects a malformed response', () async {
    final adapter = StubAdapter(statusCode: 200, body: const ['invalid']);

    await expectLater(
      DioHealthGateway(createDio(adapter)).fetch(),
      throwsA(isA<FormatException>()),
    );
  });
}

Dio createDio(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8080',
      validateStatus: (status) => status != null && status < 600,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

class StubAdapter implements HttpClientAdapter {
  StubAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;
  String? requestedPath;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPath = options.uri.path;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
