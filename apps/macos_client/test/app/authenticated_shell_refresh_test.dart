import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

import '../support/widget_network_stubs.dart';

void main() {
  testWidgets(
    'silently refreshes a page when its sidebar item is tapped again',
    (tester) async {
      final contacts = _CountingContactsController();
      final conversations = _CountingConversationsController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _StubAuthController(AuthState(session: _session)),
            ),
            contactsControllerProvider.overrideWith(() => contacts),
            conversationsControllerProvider.overrideWith(() => conversations),
            realtimeConnectionProvider.overrideWithValue(
              const StubRealtimeConnection(),
            ),
          ],
          child: const InstantChatApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chats'));
      await tester.pump();
      expect(conversations.refreshCount, 1);

      await tester.tap(find.text('Contacts'));
      await tester.pump();
      await tester.tap(find.text('Contacts'));
      await tester.pump();
      expect(contacts.refreshCount, 1);

      expect(find.text('Requests'), findsNothing);
    },
  );
}

final _session = AuthSession(
  user: AuthUser(
    id: 'operator',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 22),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 22, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 22),
);

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

class _CountingContactsController extends ContactsController {
  var refreshCount = 0;

  @override
  Future<ContactsState> build() async =>
      const ContactsState(contacts: [], incoming: [], outgoing: []);

  @override
  Future<void> refreshSilently() async {
    refreshCount++;
  }
}

class _CountingConversationsController extends ConversationsController {
  var refreshCount = 0;

  @override
  Future<ConversationsState> build() async =>
      const ConversationsState(conversations: []);

  @override
  Future<void> refreshSilently() async {
    refreshCount++;
  }
}
