import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

import '../../support/message_controller_stubs.dart';
import '../../support/conversation_controller_stubs.dart';

void main() {
  test('retry reuses the failed client message ID', () async {
    final gateway = FakeMessageGateway()..failNextSend = true;
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [testMessage('5')], nextCursor: '5'),
        MessagePage(
          messages: [testMessage('3'), testMessage('4')],
          nextCursor: null,
        ),
      ],
    );
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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

  test('loadThroughMessage pages backward until it finds the target', () async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [testMessage('5')], nextCursor: '5'),
        MessagePage(messages: [testMessage('3')], nextCursor: '3'),
        MessagePage(messages: [testMessage('2')], nextCursor: null),
      ],
    );
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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

    final found = await container
        .read(provider.notifier)
        .loadThroughMessage('2');

    expect(found, isTrue);
    expect(gateway.listIndex, 3);
    expect(
      container
          .read(provider)
          .requireValue
          .messages
          .map((message) => message.sequence),
      ['2', '3', '5'],
    );
  });

  test('sendImage appends an image message', () async {
    final gateway = FakeMessageGateway();
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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
    final gateway = FakeMessageGateway();
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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

  test('sent attachments immediately update the conversation card', () async {
    final messageGateway = FakeMessageGateway();
    final conversationGateway = FakeConversationGateway(
      createdConversation: _conversation,
      conversations: [_conversation],
    );
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
        ),
        messageGatewayProvider.overrideWithValue(messageGateway),
        conversationGatewayProvider.overrideWithValue(conversationGateway),
        realtimeConnectionProvider.overrideWithValue(realtime),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.close);
    await container.read(authControllerProvider.future);
    final conversations = container.listen(
      conversationsControllerProvider,
      (_, _) {},
    );
    final messages = container.listen(
      messagesControllerProvider('11'),
      (_, _) {},
    );
    addTearDown(conversations.close);
    addTearDown(messages.close);
    await container.read(conversationsControllerProvider.future);
    await container.read(messagesControllerProvider('11').future);

    await container
        .read(messagesControllerProvider('11').notifier)
        .sendImage('/tmp/instant-chat-image.png');
    expect(_preview(container).kind, 'image');
    await container
        .read(messagesControllerProvider('11').notifier)
        .sendFile('/tmp/instant-chat-notes.pdf');

    final preview = _preview(container);
    expect(preview.kind, 'file');
    expect(preview.fileName, 'Notes.pdf');
  });

  test('realtime events merge in server sequence order', () async {
    final gateway = FakeMessageGateway();
    final realtime = FakeRealtimeConnection();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
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
    await flushEvents();

    realtime.emitMessage(testMessage('4'));
    realtime.emitMessage(testMessage('3'));
    await flushEvents();

    expect(
      container
          .read(provider)
          .requireValue
          .messages
          .map((message) => message.sequence),
      ['3', '4'],
    );
  });

  test(
    'recall keeps an action stamp while delete removes the message',
    () async {
      final messageGateway = FakeMessageGateway(
        pages: [
          MessagePage(messages: [testMessage('5')], nextCursor: null),
          const MessagePage(messages: [], nextCursor: null),
        ],
      );
      final conversationGateway = FakeConversationGateway(
        createdConversation: _conversation,
        conversations: [_conversation],
      );
      final realtime = FakeRealtimeConnection();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => StubAuthController(AuthState(session: testAuthSession)),
          ),
          messageGatewayProvider.overrideWithValue(messageGateway),
          conversationGatewayProvider.overrideWithValue(conversationGateway),
          realtimeConnectionProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(realtime.close);
      await container.read(authControllerProvider.future);
      final conversations = container.listen(
        conversationsControllerProvider,
        (_, _) {},
      );
      final subscription = container.listen(
        messagesControllerProvider('11'),
        (_, _) {},
      );
      addTearDown(conversations.close);
      addTearDown(subscription.close);
      await container.read(conversationsControllerProvider.future);
      final provider = messagesControllerProvider('11');
      await container.read(provider.future);

      final first = container.read(provider).requireValue.messages.single;
      expect(await container.read(provider.notifier).recall(first), isTrue);
      expect(messageGateway.recalledMessageID, first.id);
      final recalled = container.read(provider).requireValue.messages.single;
      expect(recalled.recalledAt, isNotNull);
      expect(recalled.body, isEmpty);

      realtime.emitMessage(testMessage('6'));
      await flushEvents();
      final next = container.read(provider).requireValue.messages.last;
      expect(await container.read(provider.notifier).delete(next), isTrue);
      expect(messageGateway.deletedMessageID, next.id);
      expect(
        container
            .read(provider)
            .requireValue
            .messages
            .map((message) => message.id),
        [first.id],
      );
    },
  );
}

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: testMessage('1').sender,
  createdAt: DateTime.utc(2026, 7, 16, 12),
  updatedAt: DateTime.utc(2026, 7, 16, 12),
  unreadCount: 0,
);

ConversationLastMessage _preview(ProviderContainer container) => container
    .read(conversationsControllerProvider)
    .requireValue
    .conversations
    .single
    .lastMessage!;
