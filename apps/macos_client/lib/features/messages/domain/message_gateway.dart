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

  Future<Message> sendFile({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String filePath,
  });

  Future<void> recall({
    required String accessToken,
    required String conversationId,
    required String messageId,
  });

  Future<void> delete({
    required String accessToken,
    required String conversationId,
    required String messageId,
  });

  Future<List<int>> downloadFile({
    required String accessToken,
    required MessageFile file,
  });

  Future<List<int>> downloadImage({
    required String accessToken,
    required MessageImage image,
  });
}
