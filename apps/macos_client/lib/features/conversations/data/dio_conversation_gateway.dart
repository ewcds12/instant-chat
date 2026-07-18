import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';

class DioConversationGateway implements ConversationGateway {
  const DioConversationGateway(this._dio);

  final Dio _dio;

  @override
  Future<List<Conversation>> list(String accessToken) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/conversations',
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    final body = responseObject(response.data);
    return requiredList(body, 'conversations')
        .map((item) => Conversation.fromJson(_requiredObject(item)))
        .toList(growable: false);
  }

  @override
  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/conversations',
        data: {'contact_user_id': contactUserId},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200, 201});
    return Conversation.fromJson(responseObject(response.data));
  }

  @override
  Future<void> markRead({
    required String accessToken,
    required String conversationId,
    required String sequence,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/conversations/$conversationId/read',
        data: {'sequence': sequence},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {204});
  }

  Options _options(String token) =>
      Options(headers: bearerAuthorization(token));
}

Map<String, Object?> _requiredObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('conversation must be a JSON object');
  }
  return stringKeyedObject(value);
}
