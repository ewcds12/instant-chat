import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('underlines and opens a web link inside a text message', (
    tester,
  ) async {
    Uri? openedLink;
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: MessageBubble(
            message: _message,
            isMine: true,
            showSenderAvatar: false,
            imageMessages: const [],
            accessToken: '',
            onOpenFile: (_) {},
            onOpenLink: (link) async => openedLink = link,
            onDownloadImage: (_) async {},
            onRecall: (_) async => true,
            onDelete: (_) async => true,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('message-link-text-link-message')),
        matching: find.byType(RichText),
      ),
    );
    final root = richText.text as TextSpan;
    final linkSpan = _textSpans(
      root,
    ).singleWhere((span) => span.recognizer != null);
    expect(linkSpan.text, 'https://example.com/docs');
    expect(linkSpan.style?.decoration, TextDecoration.underline);

    await tester.tapOnText(
      find.textRange.ofSubstring('https://example.com/docs'),
    );
    await tester.pump();

    expect(openedLink, Uri.parse('https://example.com/docs'));
  });
}

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span case final TextSpan textSpan) {
    yield textSpan;
    for (final child in textSpan.children ?? const <InlineSpan>[]) {
      yield* _textSpans(child);
    }
  }
}

final _message = Message(
  id: 'link-message',
  conversationId: 'conversation',
  sender: PublicUser(
    id: 'sender',
    username: 'sender',
    displayName: 'Sender',
    createdAt: DateTime.utc(2026, 7, 31),
  ),
  clientMessageId: 'client-link-message',
  sequence: '1',
  kind: MessageKind.text,
  body: 'Open https://example.com/docs, please.',
  image: null,
  createdAt: DateTime.utc(2026, 7, 31),
);
