import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/realtime/domain/realtime_connection.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

final testAuthSession = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'retro_user',
    displayName: 'Retro User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 16, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 16),
);

Message testMessage(String sequence) {
  return Message(
    id: sequence,
    conversationId: '11',
    sender: PublicUser(
      id: '7',
      username: 'retro_user',
      displayName: 'Retro User',
      createdAt: DateTime.utc(2026, 7, 16),
    ),
    clientMessageId: sequence.padLeft(32, '0'),
    sequence: sequence,
    kind: MessageKind.text,
    body: 'Message $sequence',
    image: null,
    createdAt: DateTime.utc(2026, 7, 16, 13),
  );
}

class FakeMessageGateway implements MessageGateway {
  FakeMessageGateway({List<MessagePage>? pages})
    : pages = pages ?? [const MessagePage(messages: [], nextCursor: null)];

  final List<MessagePage> pages;
  final List<String> clientIDs = [];
  final List<String> afterCursors = [];
  String? sentImagePath;
  String? sentFilePath;
  String? downloadedFileID;
  String? downloadedFilePath;
  String? downloadedImageID;
  String? recalledMessageID;
  String? deletedMessageID;
  var listIndex = 0;
  var failNextSend = false;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  }) async {
    if (after != null) {
      afterCursors.add(after);
    }
    final index = listIndex < pages.length ? listIndex++ : pages.length - 1;
    return pages[index];
  }

  @override
  Future<Message> send({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String body,
  }) async {
    clientIDs.add(clientMessageId);
    if (failNextSend) {
      failNextSend = false;
      throw const ApiFailure(code: 'network_error', message: 'Offline.');
    }
    return Message(
      id: '21',
      conversationId: conversationId,
      sender: testMessage('1').sender,
      clientMessageId: clientMessageId,
      sequence: '5',
      kind: MessageKind.text,
      body: body,
      image: null,
      createdAt: DateTime.utc(2026, 7, 16, 13),
    );
  }

  @override
  Future<Message> sendImage({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String imagePath,
  }) async {
    clientIDs.add(clientMessageId);
    sentImagePath = imagePath;
    return Message(
      id: '22',
      conversationId: conversationId,
      sender: testMessage('1').sender,
      clientMessageId: clientMessageId,
      sequence: '5',
      kind: MessageKind.image,
      body: '',
      image: const MessageImage(
        id: '6',
        url: '/api/v1/message-images/6',
        contentType: 'image/png',
        byteSize: 4,
      ),
      createdAt: DateTime.utc(2026, 7, 16, 13),
    );
  }

  @override
  Future<Message> sendFile({
    required String accessToken,
    required String conversationId,
    required String clientMessageId,
    required String filePath,
  }) async {
    clientIDs.add(clientMessageId);
    sentFilePath = filePath;
    return Message(
      id: '23',
      conversationId: conversationId,
      sender: testMessage('1').sender,
      clientMessageId: clientMessageId,
      sequence: '6',
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
      createdAt: DateTime.utc(2026, 7, 16, 13),
    );
  }

  @override
  Future<void> recall({
    required String accessToken,
    required String conversationId,
    required String messageId,
  }) async {
    recalledMessageID = messageId;
  }

  @override
  Future<void> delete({
    required String accessToken,
    required String conversationId,
    required String messageId,
  }) async {
    deletedMessageID = messageId;
  }

  @override
  Future<void> downloadFile({
    required String accessToken,
    required MessageFile file,
    required String destinationPath,
  }) async {
    downloadedFileID = file.id;
    downloadedFilePath = destinationPath;
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

class FakeRealtimeConnection implements RealtimeConnection {
  final _messages = StreamController<Message>.broadcast();
  final _recalls = StreamController<MessageRecall>.broadcast();
  final _profiles = StreamController<PublicUser>.broadcast();
  final _connections = StreamController<int>.broadcast();
  var _generation = 0;

  @override
  Stream<int> get connections => _connections.stream;

  @override
  Stream<Message> get messages => _messages.stream;

  @override
  Stream<MessageRecall> get recalls => _recalls.stream;

  @override
  Stream<PublicUser> get profiles => _profiles.stream;

  @override
  void start() {}

  void emitConnection() => _connections.add(++_generation);

  void emitMessage(Message message) => _messages.add(message);

  void emitRecall(MessageRecall recall) => _recalls.add(recall);

  @override
  Future<void> close() async {
    await _messages.close();
    await _recalls.close();
    await _profiles.close();
    await _connections.close();
  }
}

class StubAuthController extends AuthController {
  StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

Future<void> flushEvents() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> waitForMessageCount(
  ProviderContainer container,
  AsyncNotifierProvider<MessagesController, MessagesState> provider,
  int count,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (container.read(provider).requireValue.messages.length == count) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for $count messages.');
}
