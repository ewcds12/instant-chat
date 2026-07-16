import 'package:dio/dio.dart';
import 'package:instant_chat/features/auth/domain/auth_failure.dart';
import 'package:instant_chat/features/auth/domain/auth_gateway.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';

class DioAuthGateway implements AuthGateway {
  const DioAuthGateway(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final response = await _post('/api/v1/auth/register', {
      'username': username,
      'display_name': displayName,
      'password': password,
    });
    return _sessionResponse(response, 201);
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _post('/api/v1/auth/login', {
      'username': username,
      'password': password,
    });
    return _sessionResponse(response, 200);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _post('/api/v1/auth/refresh', {
      'refresh_token': refreshToken,
    });
    return _sessionResponse(response, 200);
  }

  @override
  Future<AuthUser> currentUser(String accessToken) async {
    final response = await _request(
      () => _dio.get<Object?>(
        '/api/v1/auth/me',
        options: Options(headers: _authorization(accessToken)),
      ),
    );
    _expectStatus(response, 200);
    final body = _responseObject(response.data);
    final user = body['user'];
    if (user is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    return AuthUser.fromJson(stringKeyedMap(user));
  }

  @override
  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    final response = await _request(
      () => _dio.post<Object?>(
        '/api/v1/auth/logout',
        data: {'refresh_token': refreshToken},
        options: Options(headers: _authorization(accessToken)),
      ),
    );
    _expectStatus(response, 204);
  }

  Future<Response<Object?>> _post(String path, Map<String, Object?> data) {
    return _request(() => _dio.post<Object?>(path, data: data));
  }

  Future<Response<Object?>> _request(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AuthFailure(
        code: 'network_error',
        message: error.type == DioExceptionType.connectionTimeout
            ? 'The server connection timed out.'
            : 'The server could not be reached.',
      );
    }
  }

  AuthSession _sessionResponse(Response<Object?> response, int expectedStatus) {
    _expectStatus(response, expectedStatus);
    return AuthSession.fromJson(_responseObject(response.data));
  }

  void _expectStatus(Response<Object?> response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      return;
    }
    final body = _responseObject(response.data);
    final error = body['error'];
    if (error is Map<Object?, Object?>) {
      final details = stringKeyedMap(error);
      final code = details['code'];
      final message = details['message'];
      if (code is String && message is String) {
        throw AuthFailure(code: code, message: message);
      }
    }
    throw const AuthFailure(
      code: 'unexpected_response',
      message: 'The server returned an unexpected response.',
    );
  }

  Map<String, String> _authorization(String token) => {
    'Authorization': 'Bearer $token',
  };
}

Map<String, Object?> _responseObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Server response must be a JSON object');
  }
  return stringKeyedMap(value);
}
