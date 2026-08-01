import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('composer shows and cancels a reply draft', (tester) async {
    var cancelled = false;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _app(
        MessageComposer(
          controller: controller,
          focusNode: focusNode,
          disabled: false,
          recipientName: 'Peer',
          onSend: () {},
          onPickImage: () {},
          onPickFile: () {},
          replyingTo: _original,
          onCancelReply: () => cancelled = true,
        ),
      ),
    );

    expect(find.byKey(const Key('message-reply-draft')), findsOneWidget);
    expect(find.text('Retro User'), findsOneWidget);
    expect(find.text('Original message'), findsOneWidget);
    expect(find.byKey(const Key('message-composer-expanded')), findsOneWidget);
    final card = tester.widget<Container>(
      find.byKey(const Key('message-reply-draft-card')),
    );
    final cardDecoration = card.decoration! as BoxDecoration;
    expect(cardDecoration.color, isNotNull);
    expect(
      cardDecoration.borderRadius,
      BorderRadius.circular(RetroMetrics.composerReplyCardRadius),
    );
    final accent = tester.widget<Container>(
      find.byKey(const Key('message-reply-draft-accent')),
    );
    final accentDecoration = accent.decoration! as BoxDecoration;
    expect(
      accentDecoration.borderRadius,
      BorderRadius.circular(RetroMetrics.cornerPill),
    );
    expect(
      tester.getSize(find.byKey(const Key('message-reply-draft-accent'))).width,
      RetroMetrics.composerReplyAccentWidth,
    );
    final composer = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(
      (composer.decoration!.contentPadding! as EdgeInsets).top,
      RetroMetrics.composerExpandedTextTopInset,
    );

    await tester.tap(find.byKey(const Key('message-reply-cancel')));
    expect(cancelled, isTrue);
  });

  testWidgets('message bubble renders its persisted reply preview', (
    tester,
  ) async {
    final reply = MessageReply(
      id: _original.id,
      sender: _original.sender,
      kind: _original.kind,
      body: _original.body,
      filename: '',
    );
    final message = Message(
      id: '9',
      conversationId: '11',
      sender: _sender,
      clientMessageId: '9'.padLeft(32, '0'),
      sequence: '9',
      kind: MessageKind.text,
      body: 'My reply',
      image: null,
      replyTo: reply,
      createdAt: DateTime.utc(2026, 8, 1),
    );

    await tester.pumpWidget(
      _app(
        MessageBubble(
          message: message,
          isMine: true,
          showSenderAvatar: false,
          imageMessages: const [],
          accessToken: '',
          onOpenFile: (_) {},
          onOpenLink: (_) async {},
          onDownloadImage: (_) async {},
          onRecall: (_) async => true,
          onDelete: (_) async => true,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('message-reply-preview-8')),
      findsOneWidget,
    );
    expect(find.text('Original message'), findsOneWidget);
    expect(find.text('My reply'), findsOneWidget);
    final preview = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('message-reply-preview-8')),
            matching: find.byType(Container),
          )
          .first,
    );
    final previewDecoration = preview.decoration! as BoxDecoration;
    expect(previewDecoration.color, isNull);
    expect(previewDecoration.borderRadius, isNull);
    expect(
      (previewDecoration.border! as Border).left.width,
      RetroMetrics.messageReplyAccentWidth,
    );
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: RetroTheme.data,
  home: Scaffold(body: Center(child: child)),
);

final _sender = PublicUser(
  id: '7',
  username: 'retro_user',
  displayName: 'Retro User',
  createdAt: DateTime.utc(2026, 7, 16),
);

final _original = Message(
  id: '8',
  conversationId: '11',
  sender: _sender,
  clientMessageId: '8'.padLeft(32, '0'),
  sequence: '8',
  kind: MessageKind.text,
  body: 'Original message',
  image: null,
  createdAt: DateTime.utc(2026, 8, 1),
);
