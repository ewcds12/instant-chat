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

import '../../support/conversation_controller_stubs.dart';
import '../../support/widget_network_stubs.dart';

void main() {
  test(
    'recording sent attachments updates the card preview immediately',
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
      final controller = container.read(
        conversationsControllerProvider.notifier,
      );

      controller.recordMessage(_sentImage());
      expect(_preview(container).kind, 'image');
      controller.recordMessage(_sentFile());

      final preview = _preview(container);
      expect(preview.kind, 'file');
      expect(preview.fileName, 'Notes.pdf');
      expect(
        container
            .read(conversationsControllerProvider)
            .requireValue
            .conversations
            .single
            .unreadCount,
        0,
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
  peer: PublicUser.fromAuthUser(_session.user),
  createdAt: DateTime.utc(2026, 7, 16, 13),
  updatedAt: DateTime.utc(2026, 7, 16, 13),
  unreadCount: 0,
);

ConversationLastMessage _preview(ProviderContainer container) => container
    .read(conversationsControllerProvider)
    .requireValue
    .conversations
    .single
    .lastMessage!;

Message _sentImage() => _message(
  id: '13',
  sequence: '10',
  kind: MessageKind.image,
  image: const MessageImage(
    id: '6',
    url: '/api/v1/message-images/6',
    contentType: 'image/png',
    byteSize: 4,
  ),
);

Message _sentFile() => _message(
  id: '14',
  sequence: '11',
  kind: MessageKind.file,
  file: const MessageFile(
    id: '8',
    url: '/api/v1/message-files/8',
    filename: 'Notes.pdf',
    contentType: 'application/pdf',
    byteSize: 2048,
  ),
);

Message _message({
  required String id,
  required String sequence,
  required MessageKind kind,
  MessageImage? image,
  MessageFile? file,
}) => Message(
  id: id,
  conversationId: _conversation.id,
  sender: PublicUser.fromAuthUser(_session.user),
  clientMessageId: 'sent-$id',
  sequence: sequence,
  kind: kind,
  body: '',
  image: image,
  file: file,
  createdAt: DateTime.utc(2026, 7, 16, 14),
);

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}
