import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_provider.dart';

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
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SYSTEM'));
    await tester.pumpAndSettle();

    expect(find.text('ONLINE'), findsOneWidget);
    expect(
      find.textContaining('API and MySQL are operational'),
      findsOneWidget,
    );
    final pageContext = tester.element(find.text('ONLINE'));
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
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SYSTEM'));
    await tester.pumpAndSettle();

    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('RETRY CONNECTION'), findsOneWidget);
  });

  testWidgets('shows the en-US sign-in and registration forms', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(
              const AuthState(errorMessage: 'Email or password is incorrect.'),
            ),
          ),
        ],
        child: const InstantChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INSTANT CHAT // SIGN IN'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);

    await tester.tap(find.text('CREATE A NEW ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('INSTANT CHAT // REGISTER'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('DISPLAY NAME'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsNothing);
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '42',
    username: 'operator',
    email: 'operator@example.com',
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
