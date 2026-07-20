import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_recall_stamp.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('shows a neutral recall notice to both participants', (
    tester,
  ) async {
    final message = _message();

    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Column(
            children: [
              MessageRecallStamp(message: message, isMine: true),
              MessageRecallStamp(message: message, isMine: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('You recalled a message'), findsOneWidget);
    expect(find.text('Alex recalled a message'), findsOneWidget);
  });
}

Message _message() => Message(
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
  kind: MessageKind.text,
  body: '',
  image: null,
  recalledAt: DateTime.utc(2026, 7, 16, 13),
  createdAt: DateTime.utc(2026, 7, 16, 12),
);
