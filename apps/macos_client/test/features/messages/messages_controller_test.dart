import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

import '../../support/message_controller_stubs.dart';

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
}
