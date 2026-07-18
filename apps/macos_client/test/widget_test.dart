import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import 'support/widget_network_stubs.dart';

void main() {
  testWidgets('shows online when API and database are healthy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          serviceHealthProvider.overrideWith(
            (ref) async => ServiceHealth(
              status: 'healthy',
              service: 'instant-chat-api',
              database: 'healthy',
              checkedAt: DateTime.utc(2026, 7, 15, 12),
            ),
          ),
          contactsControllerProvider.overrideWith(
            () => _StubContactsController(_emptyContacts),
          ),
          conversationsControllerProvider.overrideWith(
            () => _StubConversationsController(_emptyConversations),
          ),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('System'));
    await tester.pumpAndSettle();

    expect(find.text('Online'), findsOneWidget);
    expect(
      find.textContaining('API and MySQL are operational'),
      findsOneWidget,
    );
    final pageContext = tester.element(find.text('Online'));
    expect(Localizations.localeOf(pageContext), const Locale('en', 'US'));
  });

  testWidgets('shows offline when API request fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          serviceHealthProvider.overrideWith(
            (ref) => Future<ServiceHealth>.error(StateError('offline')),
          ),
          contactsControllerProvider.overrideWith(
            () => _StubContactsController(_emptyContacts),
          ),
          conversationsControllerProvider.overrideWith(
            () => _StubConversationsController(_emptyConversations),
          ),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('System'));
    await tester.pumpAndSettle();

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
  });

  testWidgets('shows the en-US sign-in and registration forms', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(
              const AuthState(
                errorMessage: 'Username or password is incorrect.',
              ),
            ),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Username or password is incorrect.'), findsOneWidget);

    await tester.tap(find.text('New to Instant Chat? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Username or password is incorrect.'), findsNothing);
  });

  testWidgets('shows the modern navigation and filters conversations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(
            () => _StubContactsController(_emptyContacts),
          ),
          conversationsControllerProvider.overrideWith(
            () => _StubConversationsController(
              ConversationsState(conversations: [_conversation]),
            ),
          ),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chats'), findsAtLeastNWidgets(1));
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.text('Instant Chat'), findsNothing);
    expect(find.text('Other User'), findsOneWidget);
    expect(find.text('See you soon'), findsOneWidget);
    expect(find.byTooltip('New conversation'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('app-sidebar'))).width, 180);
    expect(
      tester.getSize(find.byKey(const Key('conversation-column'))).width,
      280,
    );

    await tester.enterText(
      find.byKey(const Key('conversation-search')),
      'nobody',
    );
    await tester.pump();

    expect(find.text('Other User'), findsNothing);
    expect(find.text('No matching conversations'), findsOneWidget);
  });

  testWidgets('opens a direct text channel and sends a message with Enter', (
    tester,
  ) async {
    final messageGateway = StubMessageGateway(_session.user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(
            () => _StubContactsController(_emptyContacts),
          ),
          conversationsControllerProvider.overrideWith(
            () => _StubConversationsController(
              ConversationsState(conversations: [_conversation]),
            ),
          ),
          messageGatewayProvider.overrideWithValue(messageGateway),
          realtimeConnectionProvider.overrideWithValue(
            const StubRealtimeConnection(),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other User'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Search messages'), findsOneWidget);
    expect(find.byTooltip('More options'), findsOneWidget);
    expect(find.byTooltip('Add attachment'), findsOneWidget);
    expect(find.byTooltip('Insert emoji'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('message-composer')), 'Hello.');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('@other_user'), findsOneWidget);
    expect(find.text('See you soon'), findsOneWidget);
    expect(find.text('Hello.'), findsOneWidget);
    final bubble = tester.widget<Container>(
      find.byKey(const ValueKey('message-bubble-21')),
    );
    expect(
      bubble.padding,
      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
    expect(messageGateway.sentBody, 'Hello.');
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '42',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 7, 15, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 8, 15),
);

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

const _emptyContacts = ContactsState(contacts: [], incoming: [], outgoing: []);

const _emptyConversations = ConversationsState(conversations: []);

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'other_user',
    displayName: 'Other User',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  createdAt: DateTime.utc(2026, 7, 15, 12),
  updatedAt: DateTime.utc(2026, 7, 15, 12),
  unreadCount: 0,
  lastMessage: const ConversationLastMessage(
    sequence: '1',
    kind: 'text',
    body: 'See you soon',
    fileName: '',
  ),
);

class _StubContactsController extends ContactsController {
  _StubContactsController(this.contactsState);

  final ContactsState contactsState;

  @override
  Future<ContactsState> build() async => contactsState;
}

class _StubConversationsController extends ConversationsController {
  _StubConversationsController(this.conversationsState);

  final ConversationsState conversationsState;

  @override
  Future<ConversationsState> build() async => conversationsState;
}
