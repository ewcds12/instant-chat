import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/core/platform/macos_window_controller.dart';
import 'package:instant_chat/core/platform/macos_settings_window_controller.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import 'support/widget_network_stubs.dart';

void main() {
  testWidgets('opens settings in a separate window from the sidebar', (
    tester,
  ) async {
    final settingsWindowController = _RecordingSettingsWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsWindowControllerProvider.overrideWithValue(
            settingsWindowController,
          ),
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
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

    expect(find.byTooltip('Settings'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-placeholder-button')));
    await tester.pumpAndSettle();
    expect(settingsWindowController.openCalls, 1);
    expect(find.text('System'), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('shows the en-US sign-in and registration forms', (tester) async {
    tester.view.physicalSize = const Size(
      RetroMetrics.authWindowWidth,
      RetroMetrics.authWindowHeight,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final windowController = _RecordingWindowController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appWindowControllerProvider.overrideWithValue(windowController),
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

    expect(windowController.modes, [AppWindowMode.authentication]);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Sign in to continue to Instant Chat.'), findsNothing);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Username or password is incorrect.'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('auth-form'))).width,
      RetroMetrics.authFormMaxWidth,
    );
    expect(find.byKey(const Key('auth-logo')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('auth-submit'))).height,
      RetroMetrics.authButtonHeight,
    );
    final modeButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Create an account'),
    );
    expect(
      modeButton.style?.overlayColor?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsNothing);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Username or password is incorrect.'), findsNothing);
  });

  testWidgets('shows the modern navigation and filters conversations', (
    tester,
  ) async {
    final authController = _StubAuthController(AuthState(session: _session));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => authController),
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
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Requests'), findsNothing);
    expect(find.text('Instant Chat'), findsNothing);
    expect(find.text('Other User'), findsOneWidget);
    expect(find.text('See you soon'), findsOneWidget);
    expect(find.byTooltip('New conversation'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('app-sidebar'))).width, 180);
    expect(
      tester.getSize(find.byKey(const Key('conversation-column'))).width,
      280,
    );

    await tester.tap(find.byKey(const Key('profile-account-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-sheet')), findsOneWidget);
    expect(find.text('Profile Photo'), findsNothing);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Region'), findsNothing);
    expect(find.text('Account'), findsOneWidget);
    expect(find.byKey(const Key('profile-sign-out')), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Privacy'), findsNothing);
    await tester.tap(find.byKey(const Key('profile-sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-sheet')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('conversation-search')),
      'nobody',
    );
    await tester.pump();

    expect(find.text('Other User'), findsNothing);
    expect(find.text('No matching conversations'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-account-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-sheet')), findsNothing);
    expect(authController.signOutCalls, 1);
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
    expect(find.byTooltip('More options'), findsNothing);
    expect(find.byTooltip('Add attachment'), findsOneWidget);
    expect(find.byTooltip('Insert emoji'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('message-header')),
        matching: find.byType(ProfileAvatar),
      ),
      findsNothing,
    );
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
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  var signOutCalls = 0;

  @override
  Future<AuthState> build() async => authState;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}

class _RecordingWindowController implements AppWindowController {
  final modes = <AppWindowMode>[];

  @override
  Future<void> setMode(AppWindowMode mode) async => modes.add(mode);
}

class _RecordingSettingsWindowController implements SettingsWindowController {
  var openCalls = 0;

  @override
  Future<void> open() async => openCalls += 1;
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
