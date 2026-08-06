import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/messages/presentation/message_context_menu.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('offers Reply and returns the selected message', (tester) async {
    Message? repliedTo;
    final message = _message(DateTime.now().toUtc());
    await tester.pumpWidget(
      _menu(message: message, onReply: (value) => repliedTo = value),
    );

    await _rightClick(tester, find.byKey(const Key('message-menu-target')));
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(repliedTo, same(message));
  });

  testWidgets('shows Recall for a recent outgoing message', (tester) async {
    await tester.pumpWidget(_menu(message: _message(DateTime.now().toUtc())));

    await _rightClick(tester, find.byKey(const Key('message-menu-target')));

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    final errorColor = RetroTheme.data.colorScheme.error;
    expect(tester.widget<Text>(find.text('Recall')).style?.color, errorColor);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.undo_rounded)).color,
      errorColor,
    );
  });

  testWidgets('shows Delete after the recall window expires', (tester) async {
    await tester.pumpWidget(
      _menu(
        message: _message(
          DateTime.now().toUtc().subtract(const Duration(minutes: 6)),
        ),
      ),
    );

    await _rightClick(tester, find.byKey(const Key('message-menu-target')));

    expect(find.text('Recall'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('uses the message menu instead of the text selection menu', (
    tester,
  ) async {
    await tester.pumpWidget(_bubble(message: _message(DateTime.now().toUtc())));

    await _rightClick(tester, find.byKey(const ValueKey('message-bubble-21')));

    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('uses the message menu for file cards', (tester) async {
    await tester.pumpWidget(
      _bubble(message: _fileMessage(DateTime.now().toUtc())),
    );

    await _rightClick(tester, find.byKey(const ValueKey('message-file-21')));

    expect(find.text('Recall'), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('uses an opaque elevated surface for the message menu', (
    tester,
  ) async {
    await tester.pumpWidget(_menu(message: _message(DateTime.now().toUtc())));

    await _rightClick(tester, find.byKey(const Key('message-menu-target')));

    final menuMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(menuMaterial.color, RetroTheme.data.colorScheme.surface);
    expect(menuMaterial.elevation, 12);
  });

  testWidgets('uses compact message menu rows', (tester) async {
    await tester.pumpWidget(_menu(message: _message(DateTime.now().toUtc())));

    await _rightClick(tester, find.byKey(const Key('message-menu-target')));

    final item = tester.widget<PopupMenuItem>(
      find
          .ancestor(
            of: find.text('Copy'),
            matching: find.byWidgetPredicate(
              (widget) => widget is PopupMenuItem,
            ),
          )
          .first,
    );
    expect(item.height, RetroMetrics.messageMenuItemHeight);
    expect(
      item.padding,
      const EdgeInsets.symmetric(
        horizontal: RetroMetrics.messageMenuHorizontalInset,
      ),
    );
    expect(tester.getSize(find.text('Copy')).height, lessThanOrEqualTo(18));
  });
}

Widget _menu({required Message message, ValueChanged<Message>? onReply}) =>
    MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(
        body: Center(
          child: MessageContextMenu(
            message: message,
            isMine: true,
            onRecall: (_) async => true,
            onDelete: (_) async => true,
            onReply: onReply,
            child: const SizedBox(
              key: Key('message-menu-target'),
              width: 120,
              height: 44,
            ),
          ),
        ),
      ),
    );

Widget _bubble({required Message message}) => MaterialApp(
  theme: RetroTheme.data,
  home: Scaffold(
    body: Center(
      child: MessageBubble(
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
  ),
);

Future<void> _rightClick(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

Message _message(DateTime createdAt) => Message(
  id: '21',
  conversationId: '11',
  sender: PublicUser(
    id: '7',
    username: 'retro_user',
    displayName: 'Retro User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  clientMessageId: '0123456789abcdef0123456789abcdef',
  sequence: '4',
  kind: MessageKind.text,
  body: 'Hello.',
  image: null,
  createdAt: createdAt,
);

Message _fileMessage(DateTime createdAt) => Message(
  id: '21',
  conversationId: '11',
  sender: PublicUser(
    id: '7',
    username: 'retro_user',
    displayName: 'Retro User',
    createdAt: DateTime.utc(2026, 7, 16),
  ),
  clientMessageId: '0123456789abcdef0123456789abcdef',
  sequence: '4',
  kind: MessageKind.file,
  body: '',
  image: null,
  file: const MessageFile(
    id: '5',
    url: '/api/v1/message-files/5',
    filename: 'Notes.pdf',
    contentType: 'application/pdf',
    byteSize: 1024,
  ),
  createdAt: createdAt,
);
