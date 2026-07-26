import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('top-aligns avatars with tall incoming and outgoing bubbles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Column(
            children: [
              _bubble(message: _message('incoming'), isMine: false),
              _bubble(message: _message('outgoing'), isMine: true),
            ],
          ),
        ),
      ),
    );

    _expectTopAligned(tester, 'incoming');
    _expectTopAligned(tester, 'outgoing');
  });
}

void _expectTopAligned(WidgetTester tester, String messageId) {
  final bubble = tester.getRect(
    find.byKey(ValueKey('message-bubble-$messageId')),
  );
  final avatar = tester.getRect(
    find.byKey(Key('message-sender-avatar-frame-$messageId')),
  );

  expect(bubble.height, greaterThan(avatar.height));
  expect(bubble.top, moreOrLessEquals(avatar.top));
}

Widget _bubble({required Message message, required bool isMine}) {
  return MessageBubble(
    message: message,
    isMine: isMine,
    showSenderAvatar: true,
    imageMessages: const [],
    accessToken: '',
    onOpenFile: (_) {},
    onDownloadImage: (_) async {},
    onRecall: (_) async => true,
    onDelete: (_) async => true,
  );
}

Message _message(String id) {
  return Message(
    id: id,
    conversationId: 'conversation',
    sender: _sender,
    clientMessageId: 'client-$id',
    sequence: id == 'incoming' ? '1' : '2',
    kind: MessageKind.text,
    body:
        'This message spans enough lines to make its bubble taller than '
        'the sender avatar and verify that the top edge stays anchored while '
        'the content continues downward.',
    image: null,
    createdAt: DateTime.utc(2026, 7, 26),
  );
}

final _sender = PublicUser(
  id: 'sender',
  username: 'sender',
  displayName: 'Sender',
  createdAt: DateTime.utc(2026, 7, 26),
);
