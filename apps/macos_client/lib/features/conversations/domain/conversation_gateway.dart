import 'package:instant_chat/features/conversations/domain/conversation.dart';

abstract interface class ConversationGateway {
  Future<List<Conversation>> list(String accessToken);

  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  });

  Future<void> markRead({
    required String accessToken,
    required String conversationId,
    required String sequence,
  });
}
