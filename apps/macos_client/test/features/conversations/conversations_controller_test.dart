import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/domain/conversation_gateway.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('create refreshes the direct conversation list', () async {
    final gateway = _FakeConversationGateway();
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

    await container.read(conversationsControllerProvider.notifier).create('8');

    expect(gateway.createdContactUserId, '8');
    expect(gateway.listCalls, 2);
    expect(
      container
          .read(conversationsControllerProvider)
          .requireValue
          .conversations
          .single
          .id,
      '11',
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
);

class _FakeConversationGateway implements ConversationGateway {
  int listCalls = 0;
  String? createdContactUserId;

  @override
  Future<List<Conversation>> list(String accessToken) async {
    listCalls++;
    return createdContactUserId == null ? [] : [_conversation];
  }

  @override
  Future<Conversation> createDirect({
    required String accessToken,
    required String contactUserId,
  }) async {
    createdContactUserId = contactUserId;
    return _conversation;
  }
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
