import 'dart:async';

import 'package:instant_chat/features/auth/domain/auth_user.dart';
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
