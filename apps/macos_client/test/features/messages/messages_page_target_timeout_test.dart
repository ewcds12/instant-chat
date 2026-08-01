import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/message_navigation_target.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/message_controller_stubs.dart'
    show FakeMessageGateway, StubAuthController, testAuthSession, testMessage;
import '../../support/widget_network_stubs.dart'
    show StubConversationGateway, StubRealtimeConnection;

void main() {
  testWidgets('clears the search-result highlight after three seconds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(
          messages: List.generate(30, (index) => testMessage('${index + 1}')),
          nextCursor: null,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
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
    container
        .read(messageNavigationTargetProvider.notifier)
        .select(conversationId: _conversation.id, messageId: '5');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(body: MessagesPage(conversation: _conversation)),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('message-history-target-5')),
    );

    await tester.pump(const Duration(milliseconds: 2900));
    expect(
      find.byKey(const ValueKey('message-history-target-5')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('message-history-target-5')),
      findsNothing,
    );
    expect(find.text('Message 5'), findsOneWidget);
    final history = tester.widget<ListView>(
      find.byKey(const Key('message-history-list')),
    );
    expect(
      history.controller!.position.pixels,
      lessThan(history.controller!.position.maxScrollExtent),
    );
  });
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder.');
}

final _conversation = Conversation(
  id: '11',
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'peer',
    displayName: 'Peer User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  createdAt: DateTime.utc(2026, 7, 16),
  updatedAt: DateTime.utc(2026, 7, 16),
  unreadCount: 0,
);
