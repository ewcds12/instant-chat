import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('renders a recalled message as an action stamp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: SizedBox.expand(
            child: MessageHistory(
              value: MessagesState(messages: [_recalledMessage]),
              scrollController: ScrollController(),
              accessToken: 'access-token',
              currentUserId: '7',
              onLoadOlder: () {},
              onOpenFile: (_) {},
              onOpenLink: (_) async {},
              onDownloadImage: (_) async {},
              onRecall: (_) async => true,
              onDelete: (_) async => true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Alex recalled a message'), findsOneWidget);
    expect(find.byKey(const Key('message-recall-21')), findsOneWidget);
    expect(find.byKey(const Key('message-bubble-21')), findsNothing);
    expect(find.byKey(const Key('message-sender-avatar-21')), findsNothing);
  });
}

final _recalledMessage = Message(
  id: '21',
  conversationId: '11',
  sender: PublicUser(
    id: '8',
    username: 'alex',
    displayName: 'Alex',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  clientMessageId: '0123456789abcdef0123456789abcdef',
  sequence: '4',
  kind: MessageKind.file,
  body: '',
  image: null,
  recalledAt: DateTime.utc(2026, 7, 16, 13),
  createdAt: DateTime.utc(2026, 7, 16, 12),
);
