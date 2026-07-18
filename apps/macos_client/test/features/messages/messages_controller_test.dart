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
import 'package:instant_chat/features/realtime/domain/realtime_connection.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('retry reuses the failed client message ID', () async {
    final gateway = _FakeMessageGateway()..failNextSend = true;
    final realtime = _FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final provider = messagesControllerProvider('11');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final sent = await container.read(provider.notifier).send('Hello.');
    final retried = await container.read(provider.notifier).retry();

    expect(sent, isFalse);
    expect(retried, isTrue);
    expect(gateway.clientIDs, hasLength(2));
    expect(gateway.clientIDs[0], gateway.clientIDs[1]);
    expect(
      container.read(provider).requireValue.messages.single.body,
      'Hello.',
    );
    expect(container.read(provider).requireValue.failedMessage, isNull);
  });

  test('loadOlder prepends the ascending older page', () async {
    final gateway = _FakeMessageGateway(
      pages: [
        MessagePage(messages: [_message('5')], nextCursor: '5'),
        MessagePage(messages: [_message('3'), _message('4')], nextCursor: null),
      ],
    );
    final realtime = _FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final provider = messagesControllerProvider('11');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    await container.read(provider.notifier).loadOlder();

    expect(
      container
          .read(provider)
          .requireValue
          .messages
          .map((message) => message.sequence),
      ['3', '4', '5'],
    );
    expect(container.read(provider).requireValue.nextCursor, isNull);
  });

  test('sendImage appends an image message', () async {
    final gateway = _FakeMessageGateway();
    final realtime = _FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final provider = messagesControllerProvider('11');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final sent = await container
        .read(provider.notifier)
        .sendImage('/tmp/instant-chat-image.png');

    final message = container.read(provider).requireValue.messages.single;
    expect(sent, isTrue);
    expect(gateway.sentImagePath, '/tmp/instant-chat-image.png');
    expect(message.kind, MessageKind.image);
    expect(message.image?.url, '/api/v1/message-images/6');
  });

  test('sendFile appends a file message', () async {
    final gateway = _FakeMessageGateway();
    final realtime = _FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final provider = messagesControllerProvider('11');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);

    final sent = await container
        .read(provider.notifier)
        .sendFile('/tmp/instant-chat-notes.pdf');

    final message = container.read(provider).requireValue.messages.single;
    expect(sent, isTrue);
    expect(gateway.sentFilePath, '/tmp/instant-chat-notes.pdf');
    expect(message.kind, MessageKind.file);
    expect(message.file?.filename, 'Notes.pdf');
  });

  test(
    'reconnect catches up, deduplicates, and restores sequence order',
    () async {
      final gateway = _FakeMessageGateway(
        pages: [
          MessagePage(
            messages: [_message('1'), _message('2')],
            nextCursor: null,
          ),
          MessagePage(
            messages: [_message('2'), _message('4'), _message('3')],
            nextCursor: null,
          ),
        ],
      );
      final realtime = _FakeRealtimeConnection();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          messageGatewayProvider.overrideWithValue(gateway),
          realtimeConnectionProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(realtime.close);
      await container.read(authControllerProvider.future);
      final provider = messagesControllerProvider('11');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      await _flushEvents();

      realtime.emitConnection();
      await _flushEvents();

      expect(gateway.afterCursors, ['2']);
      expect(
        container
            .read(provider)
            .requireValue
            .messages
            .map((message) => message.sequence),
        ['1', '2', '3', '4'],
      );
    },
  );

  test('realtime events merge in server sequence order', () async {
    final gateway = _FakeMessageGateway();
    final realtime = _FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final provider = messagesControllerProvider('11');
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(provider.future);
    await _flushEvents();

    realtime.emitMessage(_message('4'));
    realtime.emitMessage(_message('3'));
    await _flushEvents();

    expect(
      container
          .read(provider)
          .requireValue
          .messages
          .map((message) => message.sequence),
      ['3', '4'],
    );
  });
}

final _session = AuthSession(
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

Message _message(String sequence) {
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

class _FakeMessageGateway implements MessageGateway {
  _FakeMessageGateway({List<MessagePage>? pages})
    : pages = pages ?? [const MessagePage(messages: [], nextCursor: null)];

  final List<MessagePage> pages;
  final List<String> clientIDs = [];
  final List<String> afterCursors = [];
  String? sentImagePath;
  String? sentFilePath;
  String? downloadedFileID;
  String? downloadedImageID;
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
    return pages[listIndex++];
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
      sender: _message('1').sender,
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
      sender: _message('1').sender,
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
      sender: _message('1').sender,
      clientMessageId: clientMessageId,
      sequence: '5',
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

class _FakeRealtimeConnection implements RealtimeConnection {
  final _messages = StreamController<Message>.broadcast();
  final _connections = StreamController<int>.broadcast();
  var _generation = 0;

  @override
  Stream<int> get connections => _connections.stream;

  @override
  Stream<Message> get messages => _messages.stream;

  @override
  void start() {}

  void emitConnection() => _connections.add(++_generation);

  void emitMessage(Message message) => _messages.add(message);

  @override
  Future<void> close() async {
    await _messages.close();
    await _connections.close();
  }
}

Future<void> _flushEvents() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
