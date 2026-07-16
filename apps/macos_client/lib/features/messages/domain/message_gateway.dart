import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';

abstract interface class MessageGateway {
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  });

  Future<Message> send({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String body,
  });

  Future<Message> sendImage({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String imagePath,
  });
}
