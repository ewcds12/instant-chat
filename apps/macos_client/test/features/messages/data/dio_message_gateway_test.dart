import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/data/dio_message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

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
    expect(page.messages.single.sender.avatarUrl, '/api/v1/users/7/avatar');
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

  test('sendImage posts a multipart image message', () async {
    final image = File('${Directory.systemTemp.path}/instant-chat-test.png');
    await image.writeAsBytes([1, 2, 3]);
    addTearDown(() => image.deleteSync());
    final adapter = _StubAdapter(statusCode: 201, body: _imageMessage);
    final gateway = DioMessageGateway(_createDio(adapter));

    final message = await gateway.sendImage(
      accessToken: 'access-token',
      conversationId: '11',
      clientMessageId: '0123456789abcdef0123456789abcdef',
      imagePath: image.path,
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/conversations/11/messages/images');
    expect(adapter.formFields['client_message_id'], message.clientMessageId);
    expect(adapter.formFileKeys, ['image']);
    expect(message.kind, MessageKind.image);
    expect(message.image?.contentType, 'image/png');
  });

  test('sendFile posts a multipart file message', () async {
    final file = File('${Directory.systemTemp.path}/instant-chat-test.pdf');
    await file.writeAsBytes([1, 2, 3]);
    addTearDown(() => file.deleteSync());
    final adapter = _StubAdapter(statusCode: 201, body: _fileMessage);
    final gateway = DioMessageGateway(_createDio(adapter));

    final message = await gateway.sendFile(
      accessToken: 'access-token',
      conversationId: '11',
      clientMessageId: '0123456789abcdef0123456789abcdef',
      filePath: file.path,
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/conversations/11/messages/files');
    expect(adapter.formFields['client_message_id'], message.clientMessageId);
    expect(adapter.formFileKeys, ['file']);
    expect(message.kind, MessageKind.file);
    expect(message.file?.filename, 'Notes.pdf');
  });

  test('downloadFile fetches authenticated file bytes', () async {
    final adapter = _StubAdapter(statusCode: 200, body: [1, 2, 3]);
    final gateway = DioMessageGateway(_createDio(adapter));

    final bytes = await gateway.downloadFile(
      accessToken: 'access-token',
      file: const MessageFile(
        id: '8',
        url: '/api/v1/message-files/8',
        filename: 'Notes.pdf',
        contentType: 'application/pdf',
        byteSize: 3,
      ),
    );

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/message-files/8');
    expect(bytes, [1, 2, 3]);
  });

  test('downloadImage fetches authenticated image bytes', () async {
    final adapter = _StubAdapter(statusCode: 200, body: [4, 5, 6]);
    final gateway = DioMessageGateway(_createDio(adapter));

    final bytes = await gateway.downloadImage(
      accessToken: 'access-token',
      image: const MessageImage(
        id: '5',
        url: '/api/v1/message-images/5',
        contentType: 'image/png',
        byteSize: 3,
      ),
    );

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/message-images/5');
    expect(bytes, [4, 5, 6]);
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

  test('recall and delete use their message action endpoints', () async {
    final adapter = _StubAdapter(statusCode: 204, body: <String, Object?>{});
    final gateway = DioMessageGateway(_createDio(adapter));

    await gateway.recall(
      accessToken: 'access-token',
      conversationId: '11',
      messageId: '21',
    );
    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/conversations/11/messages/21/recall');

    await gateway.delete(
      accessToken: 'access-token',
      conversationId: '11',
      messageId: '21',
    );
    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/api/v1/conversations/11/messages/21');
  });
}

final _message = {
  'id': '21',
  'conversation_id': '11',
  'sender': {
    'id': '7',
    'username': 'retro_user',
    'display_name': 'Retro User',
    'avatar_url': '/api/v1/users/7/avatar',
    'created_at': '2026-07-16T12:00:00Z',
  },
  'client_message_id': '0123456789abcdef0123456789abcdef',
  'sequence': '5',
  'kind': 'text',
  'body': 'Hello.',
  'image': null,
  'created_at': '2026-07-16T13:00:00Z',
};

final _imageMessage = {
  ..._message,
  'id': '22',
  'sequence': '6',
  'kind': 'image',
  'body': '',
  'image': {
    'id': '5',
    'url': '/api/v1/message-images/5',
    'content_type': 'image/png',
    'byte_size': 3,
  },
};

final _fileMessage = {
  ..._message,
  'id': '23',
  'sequence': '7',
  'kind': 'file',
  'body': '',
  'image': null,
  'file': {
    'id': '8',
    'url': '/api/v1/message-files/8',
    'filename': 'Notes.pdf',
    'content_type': 'application/pdf',
    'byte_size': 2048,
  },
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
  Map<String, String> formFields = {};
  List<String> formFileKeys = [];

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
    if (options.data case final FormData formData) {
      formFields = {
        for (final field in formData.fields) field.key: field.value,
      };
      formFileKeys = [for (final file in formData.files) file.key];
    }
    if (body case final List<int> bytes) {
      return ResponseBody.fromBytes(bytes, statusCode);
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
