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
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('retry reuses the failed client message ID', () async {
    final gateway = _FakeMessageGateway()..failNextSend = true;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
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
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
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
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'retro_user',
    email: 'retro@example.com',
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
    body: 'Message $sequence',
    createdAt: DateTime.utc(2026, 7, 16, 13),
  );
}

class _FakeMessageGateway implements MessageGateway {
  _FakeMessageGateway({List<MessagePage>? pages})
    : pages = pages ?? [const MessagePage(messages: [], nextCursor: null)];

  final List<MessagePage> pages;
  final List<String> clientIDs = [];
  var listIndex = 0;
  var failNextSend = false;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    int limit = 50,
  }) async {
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
      body: body,
      createdAt: DateTime.utc(2026, 7, 16, 13),
    );
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
