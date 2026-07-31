import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';
import '../../support/conversation_controller_stubs.dart';
import '../../support/conversation_test_wait.dart';

void main() {
  test(
    'opens an existing contact chat without creating a conversation',
    () async {
      final gateway = FakeConversationGateway(
        createdConversation: _conversation,
        conversations: [_conversation],
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          conversationGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final subscription = container.listen(
        conversationsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(conversationsControllerProvider.future);

      final conversationId = await container
          .read(conversationsControllerProvider.notifier)
          .openContactChat('8');

      expect(conversationId, '11');
      expect(gateway.createdContactUserId, isNull);
      expect(gateway.listCalls, 1);
    },
  );

  test('refreshes before opening a newly accepted contact chat', () async {
    final gateway = FakeConversationGateway(
      createdConversation: _conversation,
      pages: [_otherConversation, _conversation],
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        conversationGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final subscription = container.listen(
      conversationsControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(conversationsControllerProvider.future);

    final conversationId = await container
        .read(conversationsControllerProvider.notifier)
        .openContactChat('8');

    expect(conversationId, '11');
    expect(gateway.createdContactUserId, isNull);
    expect(gateway.listCalls, 2);
  });

  test(
    'receiving a message updates unread count and moves the chat first',
    () async {
      final gateway = FakeConversationGateway(
        createdConversation: _conversation,
        conversations: [_otherConversation, _conversation],
      );
      final realtime = StreamRealtimeConnection();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          conversationGatewayProvider.overrideWithValue(gateway),
          realtimeConnectionProvider.overrideWithValue(realtime),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(realtime.close);
      await container.read(authControllerProvider.future);
      final subscription = container.listen(
        conversationsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(conversationsControllerProvider.future);

      realtime.emit(_incomingMessage());
      await Future<void>.delayed(Duration.zero);

      final conversations = container
          .read(conversationsControllerProvider)
          .requireValue
          .conversations;
      expect(conversations.first.id, _conversation.id);
      expect(conversations.first.unreadCount, 1);
      expect(conversations.first.updatedAt, DateTime.utc(2026, 7, 16, 14));
      expect(conversations.first.lastMessage?.body, 'New message');
    },
  );

  test('marking a conversation read clears its local unread badge', () async {
    final gateway = FakeConversationGateway(
      createdConversation: _conversation,
      conversations: [_conversation.copyWith(unreadCount: 3)],
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        conversationGatewayProvider.overrideWithValue(gateway),
        realtimeConnectionProvider.overrideWithValue(
          const StubRealtimeConnection(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final subscription = container.listen(
      conversationsControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(conversationsControllerProvider.future);

    final marked = await container
        .read(conversationsControllerProvider.notifier)
        .markRead(_conversation.id, '9');

    expect(marked, isTrue);
    expect(gateway.readConversationID, _conversation.id);
    expect(gateway.readSequence, '9');
    expect(
      container
          .read(conversationsControllerProvider)
          .requireValue
          .conversations
          .single
          .unreadCount,
      0,
    );
  });

  test(
    'fallback synchronization restores a missed conversation preview',
    () async {
      final recovered = _conversation.copyWith(
        updatedAt: DateTime.utc(2026, 7, 16, 14),
        lastMessage: _lastMessage,
      );
      final gateway = FakeConversationGateway(
        createdConversation: _conversation,
        pages: [_conversation, recovered],
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          conversationGatewayProvider.overrideWithValue(gateway),
          conversationRecoveryIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final subscription = container.listen(
        conversationsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(conversationsControllerProvider.future);

      await waitForConversationPreview(container);

      expect(gateway.listCalls, greaterThanOrEqualTo(2));
      expect(
        container
            .read(conversationsControllerProvider)
            .requireValue
            .conversations
            .single
            .lastMessage
            ?.body,
        'New message',
      );
    },
  );
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

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'other_user',
    displayName: 'Other User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  createdAt: DateTime.utc(2026, 7, 16, 13),
  updatedAt: DateTime.utc(2026, 7, 16, 13),
  unreadCount: 0,
);

final _otherConversation = Conversation(
  id: '12',
  kind: 'direct',
  peer: PublicUser(
    id: '9',
    username: 'third_user',
    displayName: 'Third User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  createdAt: DateTime.utc(2026, 7, 16, 13),
  updatedAt: DateTime.utc(2026, 7, 16, 13, 30),
  unreadCount: 0,
);

const _lastMessage = ConversationLastMessage(
  sequence: '9',
  kind: 'text',
  body: 'New message',
  fileName: '',
);

Message _incomingMessage() {
  return Message(
    id: '12',
    conversationId: _conversation.id,
    sender: _conversation.peer,
    clientMessageId: 'client-12',
    sequence: '9',
    kind: MessageKind.text,
    body: 'New message',
    image: null,
    createdAt: DateTime.utc(2026, 7, 16, 14),
  );
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
