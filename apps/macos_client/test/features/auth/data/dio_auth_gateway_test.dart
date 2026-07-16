import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/data/dio_auth_gateway.dart';
import 'package:instant_chat/features/auth/domain/auth_failure.dart';

void main() {
  test('login parses a session response', () async {
    final adapter = _StubAdapter(statusCode: 200, body: _sessionBody);
    final gateway = DioAuthGateway(_createDio(adapter));

    final session = await gateway.login(username: 'operator', password: 'pw');

    expect(adapter.requestedPath, '/api/v1/auth/login');
    expect(session.user.displayName, 'Operator');
    expect(session.accessToken, 'access-token');
    expect(session.refreshExpiresAt, DateTime.utc(2026, 8, 14, 12));
  });

  test('login maps the stable API error envelope', () async {
    final gateway = DioAuthGateway(
      _createDio(
        _StubAdapter(
          statusCode: 401,
          body: {
            'error': {
              'code': 'invalid_credentials',
              'message': 'Username or password is incorrect.',
              'request_id': 'request-1',
            },
          },
        ),
      ),
    );

    await expectLater(
      gateway.login(username: 'operator', password: 'incorrect-password'),
      throwsA(
        isA<AuthFailure>()
            .having((failure) => failure.code, 'code', 'invalid_credentials')
            .having(
              (failure) => failure.message,
              'message',
              'Username or password is incorrect.',
            ),
      ),
    );
  });
}

final _sessionBody = {
  'user': {
    'id': '42',
    'username': 'operator',
    'display_name': 'Operator',
    'created_at': '2026-07-15T12:00:00Z',
  },
  'access_token': 'access-token',
  'access_expires_at': '2026-07-15T12:15:00Z',
  'refresh_token': 'refresh-token',
  'refresh_expires_at': '2026-08-14T12:00:00Z',
};

Dio _createDio(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8080',
      validateStatus: (status) => status != null && status < 600,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, required this.body});

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
