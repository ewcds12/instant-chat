import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/message_controller_stubs.dart'
    show FakeMessageGateway, StubAuthController, testAuthSession, testMessage;
import '../../support/widget_network_stubs.dart'
    show StubConversationGateway, StubRealtimeConnection;

void main() {
  testWidgets('opens and highlights the message referenced by a reply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final original = testMessage('5');
    final reply = Message(
      id: '40',
      conversationId: _conversation.id,
      sender: original.sender,
      clientMessageId: '40'.padLeft(32, '0'),
      sequence: '40',
      kind: MessageKind.text,
      body: 'Reply message',
      image: null,
      replyTo: MessageReply(
        id: original.id,
        sender: original.sender,
        kind: original.kind,
        body: original.body,
        filename: '',
      ),
      createdAt: DateTime.utc(2026, 7, 16, 13, 40),
    );
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [reply], nextCursor: '40'),
        MessagePage(messages: [original], nextCursor: null),
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
      find.byKey(const ValueKey('message-reply-preview-5')),
    );

    await tester.tap(find.byKey(const ValueKey('message-reply-preview-5')));
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('message-history-target-5')),
    );

    expect(gateway.listIndex, 2);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('message-history-target-5')),
        matching: find.byKey(const ValueKey('message-bubble-5')),
      ),
      findsOneWidget,
    );
  });

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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RetroTheme.data,
          home: Scaffold(body: MessagesPage(conversation: _conversation)),
        ),
      ),
    );
    await _pumpUntil(tester, find.byTooltip('Search messages'));
    await tester.tap(find.byTooltip('Search messages'));
    await _pumpUntil(
      tester,
      find.byKey(const Key('contact-message-search-dialog')),
    );
    await tester.enterText(
      find.byKey(const Key('contact-message-search-field')),
      'Message 5',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('contact-message-search-result-5')),
    );
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('message-history-target-5')),
    );
    final targetedHistory = tester.widget<CustomScrollView>(
      find.byKey(const Key('message-history-list')),
    );
    await tester.pump();
    targetedHistory.controller!.jumpTo(0);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('message-history-target-5')),
      findsOneWidget,
    );
    final anchorFinder = find.byKey(
      const ValueKey('message-history-anchor-5'),
      skipOffstage: false,
    );
    final anchorTopBeforeHighlightEnds = tester.getTopLeft(anchorFinder).dy;
    final offsetBeforeHighlightEnds = tester
        .widget<CustomScrollView>(find.byKey(const Key('message-history-list')))
        .controller!
        .position
        .pixels;

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('message-history-target-5')),
      findsNothing,
    );
    final history = tester.widget<CustomScrollView>(
      find.byKey(const Key('message-history-list')),
    );
    expect(
      history.controller!.position.pixels,
      moreOrLessEquals(offsetBeforeHighlightEnds, epsilon: 0.01),
    );
    expect(anchorFinder, findsOneWidget);
    expect(find.text('Message 5', skipOffstage: false), findsOneWidget);
    expect(
      tester.getTopLeft(anchorFinder).dy,
      moreOrLessEquals(anchorTopBeforeHighlightEnds, epsilon: 0.01),
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
