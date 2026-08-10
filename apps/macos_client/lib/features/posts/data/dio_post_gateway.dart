import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class DioPostGateway implements PostGateway {
  const DioPostGateway(this._dio);

  final Dio _dio;

  @override
  Future<PublicPostPage> list({
    required String accessToken,
    String? before,
    int limit = 20,
  }) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/posts',
        queryParameters: {'before': ?before, 'limit': limit},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    final body = responseObject(response.data);
    final cursor = body['next_cursor'];
    if (cursor != null && cursor is! String) {
      throw const FormatException('next_cursor must be a string or null');
    }
    return PublicPostPage(
      posts: requiredList(body, 'posts')
          .map((item) => PublicPost.fromJson(_requiredObject(item)))
          .toList(growable: false),
      nextCursor: cursor as String?,
    );
  }

  @override
  Future<PublicPost> create({
    required String accessToken,
    required String body,
    required List<String> imagePaths,
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('body', body));
    for (final path in imagePaths) {
      form.files.add(MapEntry('images', await MultipartFile.fromFile(path)));
    }
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/posts',
        data: form,
        options: _uploadOptions(accessToken),
      ),
    );
    expectStatus(response, {201});
    return PublicPost.fromJson(responseObject(response.data));
  }

  @override
  Future<void> delete({required String accessToken, required String postId}) =>
      _emptyRequest(
        _dio.delete<Object?>(
          '/api/v1/posts/$postId',
          options: _options(accessToken),
        ),
      );

  @override
  Future<void> report({
    required String accessToken,
    required String postId,
    required String reason,
  }) => _emptyRequest(
    _dio.post<Object?>(
      '/api/v1/posts/$postId/reports',
      data: {'reason': reason},
      options: _options(accessToken),
    ),
  );

  @override
  Future<void> block({required String accessToken, required String userId}) =>
      _emptyRequest(
        _dio.post<Object?>(
          '/api/v1/user-blocks/$userId',
          options: _options(accessToken),
        ),
      );

  @override
  Future<void> unblock({required String accessToken, required String userId}) =>
      _emptyRequest(
        _dio.delete<Object?>(
          '/api/v1/user-blocks/$userId',
          options: _options(accessToken),
        ),
      );

  @override
  Future<List<PublicUser>> listBlocked(String accessToken) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/user-blocks',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    return requiredList(responseObject(response.data), 'users')
        .map((item) => PublicUser.fromJson(_requiredObject(item)))
        .toList(growable: false);
  }

  Future<void> _emptyRequest(Future<Response<Object?>> request) async {
    final response = await apiRequest(() => request);
    expectStatus(response, {204});
  }

  Options _options(String token) =>
      Options(headers: bearerAuthorization(token));

  Options _uploadOptions(String token) => Options(
    headers: bearerAuthorization(token),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );
}

Map<String, Object?> _requiredObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object');
  }
  return stringKeyedObject(value);
}
