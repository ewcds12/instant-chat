import 'package:dio/dio.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';

class DioMessageGateway implements MessageGateway {
  const DioMessageGateway(this._dio);

  final Dio _dio;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  }) async {
    final response = await apiRequest(
      () => _dio.get<Object?>(
        '/api/v1/conversations/$conversationId/messages',
        queryParameters: {'before': ?before, 'after': ?after, 'limit': limit},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200});
    final body = responseObject(response.data);
    final messages = requiredList(body, 'messages')
        .map((item) => Message.fromJson(_requiredObject(item)))
        .toList(growable: false);
    final cursor = body['next_cursor'];
    if (cursor != null && cursor is! String) {
      throw const FormatException('next_cursor must be a string or null');
    }
    return MessagePage(messages: messages, nextCursor: cursor as String?);
  }

  @override
  Future<Message> send({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String body,
  }) async {
    final response = await apiRequest(
      () => _dio.post<Object?>(
        '/api/v1/conversations/$conversationId/messages',
        data: {'client_message_id': clientMessageId, 'body': body},
        options: _options(accessToken),
      ),
    );
    expectStatus(response, {200, 201});
    return Message.fromJson(responseObject(response.data));
  }

  Options _options(String token) =>
      Options(headers: bearerAuthorization(token));
}

Map<String, Object?> _requiredObject(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('message must be a JSON object');
  }
  return stringKeyedObject(value);
}
