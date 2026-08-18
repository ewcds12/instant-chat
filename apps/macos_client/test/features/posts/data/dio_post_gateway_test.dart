import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/posts/data/dio_post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';

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
    expect(page.posts.single.commentCount, 3);
    expect(page.posts.single.likeCount, 8);
    expect(page.posts.single.likedByMe, isTrue);
    expect(page.posts.single.images.single.position, 0);
  });

  test('likes a post and parses the persisted count', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {'like_count': 9, 'liked_by_me': true},
    );
    final gateway = DioPostGateway(_createDio(adapter));

    final state = await gateway.like(accessToken: 'access-token', postId: '41');

    expect(adapter.method, 'PUT');
    expect(adapter.path, '/api/v1/posts/41/like');
    expect(state.likeCount, 9);
    expect(state.likedByMe, isTrue);
  });

  test('unlikes a post and parses the persisted count', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {'like_count': 8, 'liked_by_me': false},
    );
    final gateway = DioPostGateway(_createDio(adapter));

    final state = await gateway.unlike(
      accessToken: 'access-token',
      postId: '41',
    );

    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/api/v1/posts/41/like');
    expect(state.likeCount, 8);
    expect(state.likedByMe, isFalse);
  });

  test('creates and parses a post comment', () async {
    final adapter = _StubAdapter(statusCode: 201, body: _comment);
    final gateway = DioPostGateway(_createDio(adapter));

    final comment = await gateway.createComment(
      accessToken: 'access-token',
      postId: '41',
      body: 'Nice photo',
      parentCommentId: '4',
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/posts/41/comments');
    expect(adapter.data, {'body': 'Nice photo', 'parent_comment_id': '4'});
    expect(comment.body, 'Nice photo');
    expect(comment.parentCommentId, '4');
    expect(comment.author.displayName, 'Retro User');
  });

  test('lists a descending comment page', () async {
    final adapter = _StubAdapter(
      statusCode: 200,
      body: {
        'comments': [_comment],
        'next_cursor': '5',
      },
    );
    final gateway = DioPostGateway(_createDio(adapter));

    final page = await gateway.listComments(
      accessToken: 'access-token',
      postId: '41',
      before: '8',
    );

    expect(adapter.method, 'GET');
    expect(adapter.path, '/api/v1/posts/41/comments');
    expect(adapter.queryParameters['before'], '8');
    expect(page.comments.single.id, '5');
    expect(page.nextCursor, '5');
  });

  test('deletes a comment through its scoped endpoint', () async {
    final adapter = _StubAdapter(statusCode: 204, body: '');
    final gateway = DioPostGateway(_createDio(adapter));

    await gateway.deleteComment(
      accessToken: 'access-token',
      postId: '41',
      commentId: '5',
    );

    expect(adapter.method, 'DELETE');
    expect(adapter.path, '/api/v1/posts/41/comments/5');
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

  test('downloadImage fetches authenticated image bytes', () async {
    final adapter = _StubAdapter(statusCode: 200, body: <int>[4, 5, 6]);
    final gateway = DioPostGateway(_createDio(adapter));

    final bytes = await gateway.downloadImage(
      accessToken: 'access-token',
      image: const PublicPostImage(
        id: '3',
        position: 0,
        contentType: 'image/png',
        byteSize: 3,
        url: '/api/v1/post-images/3',
      ),
    );

    expect(adapter.path, '/api/v1/post-images/3');
    expect(adapter.authorization, 'Bearer access-token');
    expect(bytes, [4, 5, 6]);
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
  'comment_count': 3,
  'like_count': 8,
  'liked_by_me': true,
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

final _comment = {
  'id': '5',
  'post_id': '41',
  'parent_comment_id': '4',
  'author': _post['author'],
  'body': 'Nice photo',
  'created_at': '2026-08-09T09:30:00Z',
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
  Map<String, dynamic> queryParameters = const {};

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
    queryParameters = options.queryParameters;
    if (body is List<int>) {
      return ResponseBody.fromBytes(body as List<int>, statusCode);
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
