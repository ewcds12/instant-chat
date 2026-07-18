import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

import '../../support/message_controller_stubs.dart';

void main() {
  test('initial recovery catches up after the history snapshot', () async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(
          messages: [testMessage('1'), testMessage('2')],
          nextCursor: null,
        ),
        MessagePage(
          messages: [testMessage('2'), testMessage('4'), testMessage('3')],
          nextCursor: null,
        ),
      ],
    );
    final harness = await _createHarness(gateway);
    addTearDown(harness.close);

    await flushEvents();

    expect(gateway.afterCursors, ['2']);
    expect(_sequences(harness), ['1', '2', '3', '4']);
  });

  test('reconnect catches up and restores sequence order', () async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(
          messages: [testMessage('1'), testMessage('2')],
          nextCursor: null,
        ),
        const MessagePage(messages: [], nextCursor: null),
        MessagePage(
          messages: [testMessage('2'), testMessage('4'), testMessage('3')],
          nextCursor: null,
        ),
      ],
    );
    final harness = await _createHarness(gateway);
    addTearDown(harness.close);
    await flushEvents();

    harness.realtime.emitConnection();
    await flushEvents();

    expect(gateway.afterCursors, ['2', '2']);
    expect(_sequences(harness), ['1', '2', '3', '4']);
  });

  test('a sequence gap triggers recovery without a reconnect', () async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [testMessage('8')], nextCursor: null),
        const MessagePage(messages: [], nextCursor: null),
        MessagePage(
          messages: [testMessage('9'), testMessage('10')],
          nextCursor: null,
        ),
      ],
    );
    final harness = await _createHarness(gateway);
    addTearDown(harness.close);
    await flushEvents();

    harness.realtime.emitMessage(testMessage('10'));
    await flushEvents();

    expect(gateway.afterCursors, ['8', '8']);
    expect(_sequences(harness), ['8', '9', '10']);
  });

  test('fallback recovery fetches a missed final realtime message', () async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [testMessage('1')], nextCursor: null),
        const MessagePage(messages: [], nextCursor: null),
        MessagePage(messages: [testMessage('2')], nextCursor: null),
      ],
    );
    final harness = await _createHarness(
      gateway,
      interval: const Duration(milliseconds: 10),
    );
    addTearDown(harness.close);

    await waitForMessageCount(harness.container, harness.provider, 2);

    expect(_sequences(harness), ['1', '2']);
  });
}

class _Harness {
  const _Harness({
    required this.container,
    required this.provider,
    required this.subscription,
    required this.realtime,
  });

  final ProviderContainer container;
  final AsyncNotifierProvider<MessagesController, MessagesState> provider;
  final ProviderSubscription<AsyncValue<MessagesState>> subscription;
  final FakeRealtimeConnection realtime;

  Future<void> close() async {
    subscription.close();
    container.dispose();
    await realtime.close();
  }
}

Future<_Harness> _createHarness(
  FakeMessageGateway gateway, {
  Duration interval = const Duration(seconds: 2),
}) async {
  final realtime = FakeRealtimeConnection();
  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => StubAuthController(AuthState(session: testAuthSession)),
      ),
      messageGatewayProvider.overrideWithValue(gateway),
      messageRecoveryIntervalProvider.overrideWithValue(interval),
      realtimeConnectionProvider.overrideWithValue(realtime),
    ],
  );
  await container.read(authControllerProvider.future);
  final provider = messagesControllerProvider('11');
  final subscription = container.listen(provider, (_, _) {});
  await container.read(provider.future);
  return _Harness(
    container: container,
    provider: provider,
    subscription: subscription,
    realtime: realtime,
  );
}

Iterable<String> _sequences(_Harness harness) {
  return harness.container
      .read(harness.provider)
      .requireValue
      .messages
      .map((message) => message.sequence);
}
