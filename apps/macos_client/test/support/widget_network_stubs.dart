import 'dart:async';

import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/realtime/domain/realtime_connection.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class StubMessageGateway implements MessageGateway {
  StubMessageGateway(this.sender, {this.initialMessages = const []});

  final AuthUser sender;
  final List<Message> initialMessages;
  String? sentBody;
  String? sentImagePath;
  String? sentFilePath;
  String? downloadedFileID;
  String? downloadedImageID;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  }) async {
    return MessagePage(messages: initialMessages, nextCursor: null);
  }

  @override
  Future<Message> send({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String body,
  }) async {
    sentBody = body;
    return Message(
      id: '21',
      conversationId: conversationId,
      sender: PublicUser.fromAuthUser(sender),
      clientMessageId: clientMessageId,
      sequence: '1',
      kind: MessageKind.text,
      body: body,
      image: null,
      createdAt: DateTime.utc(2026, 7, 15, 13),
    );
  }

  @override
  Future<Message> sendImage({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String imagePath,
  }) async {
    sentImagePath = imagePath;
    return Message(
      id: '22',
      conversationId: conversationId,
      sender: PublicUser.fromAuthUser(sender),
      clientMessageId: clientMessageId,
      sequence: '2',
      kind: MessageKind.image,
      body: '',
      image: const MessageImage(
        id: '5',
        url: '/api/v1/message-images/5',
        contentType: 'image/png',
        byteSize: 3,
      ),
      createdAt: DateTime.utc(2026, 7, 15, 13),
    );
  }

  @override
  Future<Message> sendFile({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String filePath,
  }) async {
    sentFilePath = filePath;
    return Message(
      id: '23',
      conversationId: conversationId,
      sender: PublicUser.fromAuthUser(sender),
      clientMessageId: clientMessageId,
      sequence: '3',
      kind: MessageKind.file,
      body: '',
      image: null,
      file: const MessageFile(
        id: '8',
        url: '/api/v1/message-files/8',
        filename: 'Notes.pdf',
        contentType: 'application/pdf',
        byteSize: 2048,
      ),
      createdAt: DateTime.utc(2026, 7, 15, 13),
    );
  }

  @override
  Future<List<int>> downloadFile({
    required String accessToken,
    required MessageFile file,
  }) async {
    downloadedFileID = file.id;
    return [1, 2, 3];
  }

  @override
  Future<List<int>> downloadImage({
    required String accessToken,
    required MessageImage image,
  }) async {
    downloadedImageID = image.id;
    return [4, 5, 6];
  }
}

class StubConversationGateway implements ConversationGateway {
  String? readConversationID;
  String? readSequence;

  @override
  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  }) => throw UnimplementedError();

  @override
  Future<List<Conversation>> list(String accessToken) async => const [];

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

class StubRealtimeConnection implements RealtimeConnection {
  const StubRealtimeConnection();

  @override
  Stream<int> get connections => const Stream.empty();

  @override
  Stream<Message> get messages => const Stream.empty();

  @override
  void start() {}

  @override
  Future<void> close() async {}
}

class StreamRealtimeConnection implements RealtimeConnection {
  final _messages = StreamController<Message>.broadcast();

  @override
  Stream<int> get connections => const Stream.empty();

  @override
  Stream<Message> get messages => _messages.stream;

  @override
  void start() {}

  void emit(Message message) => _messages.add(message);

  @override
  Future<void> close() async {
    await _messages.close();
  }
}
