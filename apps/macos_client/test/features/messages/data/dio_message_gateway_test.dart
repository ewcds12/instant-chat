import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/data/dio_message_gateway.dart';

void main() {
  test('list parses messages and the older-page cursor', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {
        'messages': [_message],
        'next_cursor': '4',
      },
    );
    final gateway = DioMessageGateway(_createDio(adapter));

    final page = await gateway.list(
      accessToken: 'access-token',
      conversationId: '11',
      before: '8',
    );

    expect(adapter.path, '/api/v1/conversations/11/messages');
    expect(adapter.query['before'], '8');
    expect(page.messages.single.sequence, '5');
    expect(page.nextCursor, '4');
  });

  test('send accepts an idempotent existing-message response', () async {
    final adapter = _StubAdapter(statusCode: 200, body: _message);
    final gateway = DioMessageGateway(_createDio(adapter));

    final message = await gateway.send(
      accessToken: 'access-token',
      conversationId: '11',
      clientMessageId: '0123456789abcdef0123456789abcdef',
      body: 'Hello.',
    );

    expect(adapter.method, 'POST');
    expect(adapter.data['client_message_id'], message.clientMessageId);
    expect(message.body, 'Hello.');
  });

  test('list sends the reconnect sequence cursor', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {'messages': <Object>[], 'next_cursor': null},
    );
    final gateway = DioMessageGateway(_createDio(adapter));

    await gateway.list(
      accessToken: 'access-token',
      conversationId: '11',
      after: '8',
      limit: 100,
    );

    expect(adapter.query['after'], '8');
    expect(adapter.query['limit'], 100);
  });
}

final _message = {
  'id': '21',
  'conversation_id': '11',
  'sender': {
    'id': '7',
    'username': 'retro_user',
    'display_name': 'Retro User',
    'created_at': '2026-07-16T12:00:00Z',
  },
  'client_message_id': '0123456789abcdef0123456789abcdef',
  'sequence': '5',
  'body': 'Hello.',
  'created_at': '2026-07-16T13:00:00Z',
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
  Map<String, dynamic> query = {};
  Map<String, dynamic> data = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    query = options.queryParameters;
    if (options.data case final Map<String, dynamic> requestData) {
      data = requestData;
    }
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
