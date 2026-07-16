import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/conversations/data/dio_conversation_gateway.dart';

void main() {
  test('list parses direct conversations', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {
        'conversations': [_conversation],
      },
    );
    final gateway = DioConversationGateway(_createDio(adapter));

    final conversations = await gateway.list('access-token');

    expect(adapter.path, '/api/v1/conversations');
    expect(conversations.single.id, '11');
    expect(conversations.single.peer.username, 'other_user');
  });

  test('createDirect accepts an existing conversation response', () async {
    final adapter = _StubAdapter(statusCode: 200, body: _conversation);
    final gateway = DioConversationGateway(_createDio(adapter));

    final conversation = await gateway.createDirect(
      accessToken: 'access-token',
      contactUserId: '8',
    );

    expect(conversation.kind, 'direct');
    expect(adapter.method, 'POST');
  });
}

final _conversation = {
  'id': '11',
  'kind': 'direct',
  'peer': {
    'id': '8',
    'username': 'other_user',
    'display_name': 'Other User',
    'created_at': '2026-07-16T12:00:00Z',
  },
  'created_at': '2026-07-16T13:00:00Z',
  'updated_at': '2026-07-16T13:00:00Z',
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
  String? method;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
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
