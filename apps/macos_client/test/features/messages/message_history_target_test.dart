import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('anchors and highlights a selected history message', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: MessageHistory(
            value: MessagesState(
              messages: [
                _message('first', 'First message', '1'),
                _message('target', 'Selected message', '2'),
                _message('latest', 'Latest message', '3'),
              ],
            ),
            scrollController: controller,
            accessToken: 'access-token',
            currentUserId: 'current-user',
            targetMessageId: 'target',
            highlightedMessageId: 'target',
            onLoadOlder: () {},
            onOpenFile: (_) {},
            onOpenLink: (_) async {},
            onDownloadImage: (_) async {},
            onRecall: (_) async => true,
            onDelete: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('message-history-target-target')),
      findsOneWidget,
    );
    final history = tester.widget<CustomScrollView>(
      find.byKey(const Key('message-history-list')),
    );
    expect(history.anchor, 0.34);
    expect(history.center, const ValueKey('message-history-center-target'));
  });
}

final _peer = PublicUser(
  id: 'peer-user',
  username: 'peer',
  displayName: 'Peer User',
  createdAt: DateTime.utc(2026, 7, 1),
);

Message _message(String id, String body, String sequence) {
  return Message(
    id: id,
    conversationId: 'conversation-1',
    sender: _peer,
    clientMessageId: 'client-$id',
    sequence: sequence,
    kind: MessageKind.text,
    body: body,
    image: null,
    createdAt: DateTime.utc(2026, 7, 1, 12, int.parse(sequence)),
  );
}
