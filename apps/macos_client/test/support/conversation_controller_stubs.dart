import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';

class FakeConversationGateway implements ConversationGateway {
  FakeConversationGateway({
    required this.createdConversation,
    this.conversations = const [],
    this.pages = const [],
  });

  final Conversation createdConversation;
  final List<Conversation> conversations;
  final List<Conversation> pages;
  int listCalls = 0;
  String? createdContactUserId;
  String? readConversationID;
  String? readSequence;

  @override
  Future<List<Conversation>> list(String accessToken) async {
    listCalls++;
    if (pages.isNotEmpty) {
      final index = listCalls - 1 < pages.length
          ? listCalls - 1
          : pages.length - 1;
      return [pages[index]];
    }
    return createdContactUserId == null ? conversations : [createdConversation];
  }

  @override
  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  }) async {
    createdContactUserId = contactUserId;
    return createdConversation;
  }

  @override
  Future<void> markRead({
    required String accessToken,
    required String conversationId,
    required String sequence,
  }) async {
    readConversationID = conversationId;
    readSequence = sequence;
  }
}
