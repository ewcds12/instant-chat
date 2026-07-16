import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_failure.dart';

Future<Response<Object?>> apiRequest(
  Future<Response<Object?>> Function() request,
) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw ApiFailure(
      code: 'network_error',
      message: error.type == DioExceptionType.connectionTimeout
          ? 'The server connection timed out.'
          : 'The server could not be reached.',
    );
  }
}

void expectStatus(Response<Object?> response, Set<int> expected) {
  if (expected.contains(response.statusCode)) {
    return;
  }
  final body = responseObject(response.data);
  final error = body['error'];
  if (error is Map<Object?, Object?>) {
    final details = stringKeyedObject(error);
    final code = details['code'];
    final message = details['message'];
    if (code is String && message is String) {
      throw ApiFailure(code: code, message: message);
    }
  }
  throw const ApiFailure(
    code: 'unexpected_response',
    message: 'The server returned an unexpected response.',
  );
}

Map<String, Object?> responseObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Server response must be a JSON object');
  }
  return stringKeyedObject(value);
}

Map<String, Object?> stringKeyedObject(Map<Object?, Object?> value) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key case final String key) {
      result[key] = entry.value;
    } else {
      throw const FormatException('JSON object keys must be strings');
    }
  }
  return result;
}

List<Object?> requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('$key must be a JSON array');
  }
  return value;
}

Map<String, String> bearerAuthorization(String token) => {
  'Authorization': 'Bearer $token',
};
