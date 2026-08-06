import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_selection.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/widget_network_stubs.dart';

void main() {
  testWidgets('opens contact info over the chat and returns to messages', (
    tester,
  ) async {
    final removal = _RemovalTracker();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _StubAuthController(AuthState(session: _session)),
        ),
        contactsControllerProvider.overrideWith(
          () => _StubContactsController(removal),
        ),
        contactSharedContentProvider.overrideWith(
          (ref, request) async => const ContactSharedContent.empty(),
        ),
        messageGatewayProvider.overrideWithValue(
          StubMessageGateway(_session.user),
        ),
        conversationRecoveryIntervalProvider.overrideWithValue(null),
        messageRecoveryIntervalProvider.overrideWithValue(null),
        conversationGatewayProvider.overrideWithValue(
          StubConversationGateway(),
        ),
        realtimeConnectionProvider.overrideWithValue(
          const StubRealtimeConnection(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(body: MessagesPage(conversation: _conversation)),
        ),
      ),
    );
    await _pumpUntil(tester, find.byKey(const Key('message-header')));

    final searchCenter = tester.getCenter(
      find.byKey(const Key('message-search-open')),
    );
    final infoCenter = tester.getCenter(
      find.byKey(const Key('message-contact-info-open')),
    );
    expect(infoCenter.dx, greaterThan(searchCenter.dx));

    await tester.tap(find.byKey(const Key('message-contact-info-open')));
    await _pumpUntil(tester, find.byKey(const Key('contact-detail-header')));

    expect(find.byKey(const Key('message-header')), findsNothing);
    expect(find.byKey(const Key('contact-detail-back')), findsOneWidget);
    expect(find.text('Contact Info'), findsOneWidget);
    expect(find.text(_conversation.peer.displayName), findsOneWidget);

    await tester.tap(find.byKey(const Key('contact-detail-back')));
    await _pumpUntil(tester, find.byKey(const Key('message-header')));

    expect(find.byKey(const Key('contact-detail-header')), findsNothing);
    expect(find.byKey(const Key('message-composer')), findsOneWidget);

    container
        .read(selectedConversationIdProvider.notifier)
        .select(_conversation.id);
    await tester.tap(find.byKey(const Key('message-contact-info-open')));
    await _pumpUntil(tester, find.byKey(const Key('contact-detail-header')));
    await tester.tap(find.byTooltip('Contact options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Contact…'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Contact?'), findsOneWidget);
    expect(find.textContaining('Message history will return'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(removal.userId, _conversation.peer.id);
    expect(container.read(selectedConversationIdProvider), isNull);
  });
}

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

class _StubContactsController extends ContactsController {
  _StubContactsController(this.removal);

  final _RemovalTracker removal;

  @override
  Future<ContactsState> build() async =>
      const ContactsState(contacts: [], incoming: [], outgoing: []);

  @override
  Future<bool> remove(String userId) async {
    removal.userId = userId;
    return true;
  }
}

class _RemovalTracker {
  String? userId;
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder.');
}

final _session = AuthSession(
  user: AuthUser(
    id: '42',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 8, 1),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 8, 1, 13),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 9, 1),
);

final _conversation = Conversation(
  id: 'conversation-1',
  kind: 'direct',
  peer: PublicUser(
    id: 'peer-1',
    username: 'antoine',
    displayName: 'Antoine Griezmann',
    createdAt: DateTime.utc(2026, 8, 1),
  ),
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
  unreadCount: 0,
);
