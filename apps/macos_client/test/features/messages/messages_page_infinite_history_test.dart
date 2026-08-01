import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../support/message_controller_stubs.dart';
import '../../support/widget_network_stubs.dart';

void main() {
  testWidgets('loads older messages on upward scroll without jumping', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gateway = _DelayedHistoryGateway();
    addTearDown(gateway.completeOlderPage);
    final realtime = FakeRealtimeConnection();
    addTearDown(realtime.close);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => StubAuthController(AuthState(session: testAuthSession)),
        ),
        messageGatewayProvider.overrideWithValue(gateway),
        messageRecoveryIntervalProvider.overrideWithValue(null),
        conversationRecoveryIntervalProvider.overrideWithValue(null),
        conversationGatewayProvider.overrideWithValue(
          StubConversationGateway(),
        ),
        realtimeConnectionProvider.overrideWithValue(realtime),
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
    await _pumpUntil(tester, find.byKey(const Key('message-history-list')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Load older messages'), findsNothing);
    final historyFinder = find.byKey(const Key('message-history-list'));
    await tester.drag(
      historyFinder,
      const Offset(0, 4000),
      kind: PointerDeviceKind.trackpad,
    );
    await _pumpUntil(
      tester,
      find.byKey(const Key('message-history-loading-older')),
    );

    expect(gateway.olderRequestCount, 1);
    final history = tester.widget<ListView>(
      find.byKey(const Key('message-history-list')),
    );
    final position = history.controller!.position;
    final distanceFromBottomBeforeLoad =
        position.maxScrollExtent - position.pixels;

    await tester.drag(historyFinder, const Offset(0, 120));
    await tester.pump();
    expect(gateway.olderRequestCount, 1);

    gateway.completeOlderPage();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    final state = container
        .read(messagesControllerProvider(_conversation.id))
        .requireValue;
    expect(state.messages, hasLength(40));
    expect(state.nextCursor, isNull);
    expect(
      position.maxScrollExtent - position.pixels,
      closeTo(distanceFromBottomBeforeLoad, 1),
    );
  });
}

class _DelayedHistoryGateway extends FakeMessageGateway {
  final _olderPage = Completer<MessagePage>();
  var olderRequestCount = 0;

  @override
  Future<MessagePage> list({
    required String accessToken,
    required String conversationId,
    String? before,
    String? after,
    int limit = 50,
  }) {
    if (after != null) {
      return Future.value(const MessagePage(messages: [], nextCursor: null));
    }
    if (before == null) {
      return Future.value(
        MessagePage(
          messages: [
            for (var index = 21; index <= 40; index++) testMessage('$index'),
          ],
          nextCursor: '21',
        ),
      );
    }
    olderRequestCount += 1;
    return _olderPage.future;
  }

  void completeOlderPage() {
    if (_olderPage.isCompleted) {
      return;
    }
    _olderPage.complete(
      MessagePage(
        messages: [
          for (var index = 1; index <= 20; index++) testMessage('$index'),
        ],
        nextCursor: null,
      ),
    );
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
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
    username: 'other_user',
    displayName: 'Other User',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  createdAt: DateTime.utc(2026, 7, 15, 12),
  updatedAt: DateTime.utc(2026, 7, 15, 12),
  unreadCount: 0,
);
