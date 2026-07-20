import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_list_row.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('uses generic labels for attachment previews', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ConversationListRow(
                conversation: _conversation('image', 'holiday.png'),
                selected: false,
                accessToken: 'access-token',
                onOpen: () {},
              ),
              ConversationListRow(
                conversation: _conversation('file', 'notes.pdf'),
                selected: false,
                accessToken: 'access-token',
                onOpen: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('[Image]'), findsOneWidget);
    expect(find.text('[File]'), findsOneWidget);
    expect(find.text('holiday.png'), findsNothing);
    expect(find.text('notes.pdf'), findsNothing);
  });
}

Conversation _conversation(String kind, String fileName) => Conversation(
  id: kind,
  kind: 'direct',
  peer: PublicUser(
    id: '8',
    username: 'other_user',
    displayName: 'Other User',
    createdAt: DateTime.utc(2026, 7, 15),
  ),
  createdAt: DateTime.utc(2026, 7, 15),
  updatedAt: DateTime.utc(2026, 7, 15),
  unreadCount: 0,
  lastMessage: ConversationLastMessage(
    sequence: '1',
    kind: kind,
    body: '',
    fileName: fileName,
  ),
);
