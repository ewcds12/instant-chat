import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/posts/data/dio_post_gateway.dart';

void main() {
  test('list parses posts, images, and the pagination cursor', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {
        'posts': [_post],
        'next_cursor': '40',
      },
    );
    final gateway = DioPostGateway(_createDio(adapter));

    final page = await gateway.list(accessToken: 'access-token');

    expect(adapter.path, '/api/v1/posts');
    expect(adapter.authorization, 'Bearer access-token');
    expect(page.nextCursor, '40');
    expect(page.posts.single.body, 'Hello everyone');
    expect(page.posts.single.images.single.position, 0);
  });

  test('report sends the reason to the post report endpoint', () async {
    final adapter = _StubAdapter(statusCode: 204, body: '');
    final gateway = DioPostGateway(_createDio(adapter));

    await gateway.report(
      accessToken: 'access-token',
      postId: '41',
      reason: 'Spam',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/posts/41/reports');
    expect(adapter.data, {'reason': 'Spam'});
  });
}

final _post = {
  'id': '41',
  'author': {
    'id': '7',
    'username': 'retro_user',
    'display_name': 'Retro User',
    'avatar_url': null,
    'created_at': '2026-08-09T08:00:00Z',
  },
  'body': 'Hello everyone',
  'images': [
    {
      'id': '3',
      'position': 0,
      'content_type': 'image/png',
      'byte_size': 8,
      'url': '/api/v1/post-images/3',
    },
  ],
  'created_at': '2026-08-09T09:00:00Z',
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
  String? authorization;
  Object? data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    method = options.method;
    authorization = options.headers['Authorization'] as String?;
    data = options.data;
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
