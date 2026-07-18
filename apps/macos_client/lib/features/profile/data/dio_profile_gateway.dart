import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/profile/domain/profile_gateway.dart';
import 'package:instant_chat/features/profile/domain/profile_update.dart';

class DioProfileGateway implements ProfileGateway {
  const DioProfileGateway(this._dio);

  final Dio _dio;

  @override
  Future<AuthUser> update({
    required String accessToken,
    required ProfileUpdate update,
  }) async {
    final response = await apiRequest(
      () => _dio.patch<Object?>(
        '/api/v1/auth/me',
        data: update.toJson(),
        options: Options(headers: bearerAuthorization(accessToken)),
      ),
    );
    expectStatus(response, {200});
    return _userFromResponse(response.data);
  }

  @override
  Future<AuthUser> uploadAvatar({
    required String accessToken,
    required String imagePath,
  }) async {
    final response = await apiRequest(
      () async => _dio.put<Object?>(
        '/api/v1/auth/me/avatar',
        data: FormData.fromMap({
          'avatar': await MultipartFile.fromFile(imagePath),
        }),
        options: Options(
          headers: bearerAuthorization(accessToken),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ),
    );
    expectStatus(response, {200});
    return _userFromResponse(response.data);
  }

  AuthUser _userFromResponse(Object? body) {
    final response = responseObject(body);
    final user = response['user'];
    if (user is! Map<Object?, Object?>) {
      throw const FormatException('user must be a JSON object');
    }
    return AuthUser.fromJson(_stringKeyedMap(user));
  }
}

Map<String, Object?> _stringKeyedMap(Map<Object?, Object?> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('user keys must be strings');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}
