import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/features/contacts/data/dio_contact_gateway.dart';

void main() {
  test('listContacts parses the public contact contract', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {
        'contacts': [
          {
            'relationship_id': '9',
            'user': _publicUser,
            'connected_at': '2026-07-16T13:00:00Z',
          },
        ],
      },
    );
    final gateway = DioContactGateway(_createDio(adapter));

    final contacts = await gateway.listContacts('access-token');

    expect(adapter.path, '/api/v1/contacts');
    expect(adapter.authorization, 'Bearer access-token');
    expect(contacts.single.user.username, 'other_user');
    expect(contacts.single.relationshipId, '9');
  });

  test('searchUser maps a stable API error', () async {
    final gateway = DioContactGateway(
      _createDio(
        _StubAdapter(
          statusCode: 404,
          body: {
            'error': {
              'code': 'user_not_found',
              'message': 'No account uses that username.',
              'request_id': 'request-1',
            },
          },
        ),
      ),
    );

    await expectLater(
      gateway.searchUser(accessToken: 'access-token', username: 'missing_user'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'user_not_found',
        ),
      ),
    );
  });

  test('cancelRequest posts to the outgoing request endpoint', () async {
    final adapter = _StubAdapter(statusCode: 204, body: '');
    final gateway = DioContactGateway(_createDio(adapter));

    await gateway.cancelRequest(accessToken: 'access-token', requestId: '9');

    expect(adapter.path, '/api/v1/contact-requests/9/cancel');
    expect(adapter.authorization, 'Bearer access-token');
  });
}

final _publicUser = {
  'id': '8',
  'username': 'other_user',
  'display_name': 'Other User',
  'created_at': '2026-07-16T12:00:00Z',
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
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
