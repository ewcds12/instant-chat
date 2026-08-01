import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_message_search.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_page.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

import '../../../support/message_controller_stubs.dart';

void main() {
  testWidgets('loads every history page and returns the selected result', (
    tester,
  ) async {
    final gateway = FakeMessageGateway(
      pages: [
        MessagePage(messages: [_message('latest', 'Latest')], nextCursor: '8'),
        MessagePage(
          messages: [_message('target', 'Project handoff details')],
          nextCursor: null,
        ),
      ],
    );
    Message? selected;
    await tester.binding.setSurfaceSize(const Size(1000, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  selected = await showContactMessageSearch(
                    context: context,
                    contact: _contact,
                    currentUserId: 'current-user',
                    conversationId: 'conversation-1',
                    accessToken: 'access-token',
                    gateway: gateway,
                  );
                },
                child: const Text('Search'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('contact-message-search-field')),
      'project',
    );
    await tester.pumpAndSettle();

    expect(gateway.listIndex, 2);
    expect(
      find.byKey(const ValueKey('contact-message-search-result-target')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('contact-message-search-result-target')),
    );
    await tester.pumpAndSettle();

    expect(selected?.id, 'target');
  });

  test('filters recalled messages and sorts matches newest first', () {
    final older = _message('older', 'Project one');
    final newer = _message(
      'newer',
      'Project two',
      createdAt: DateTime.utc(2026, 7, 31),
    );
    final recalled = _message(
      'recalled',
      'Project hidden',
    ).recalled(DateTime.utc(2026, 8, 1));

    final matches = searchContactMessages([
      older,
      recalled,
      newer,
    ], ' PROJECT ');

    expect(matches.map((message) => message.id), ['newer', 'older']);
  });
}

final _peer = PublicUser(
  id: 'peer-user',
  username: 'antoine',
  displayName: 'Antoine Griezmann',
  createdAt: DateTime.utc(2026, 7, 1),
);

final _contact = Contact(
  relationshipId: 'relationship-1',
  user: _peer,
  connectedAt: DateTime.utc(2026, 7, 1),
);

Message _message(String id, String body, {DateTime? createdAt}) {
  return Message(
    id: id,
    conversationId: 'conversation-1',
    sender: _peer,
    clientMessageId: 'client-$id',
    sequence: id == 'latest' ? '9' : '1',
    kind: MessageKind.text,
    body: body,
    image: null,
    createdAt: createdAt ?? DateTime.utc(2026, 7, 1),
  );
}
