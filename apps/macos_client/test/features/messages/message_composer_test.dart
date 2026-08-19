import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';

void main() {
  testWidgets('attachment menu can reopen after choosing photo', (
    tester,
  ) async {
    var picks = 0;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MessageComposer(
              controller: controller,
              focusNode: focusNode,
              disabled: false,
              recipientName: 'Sam',
              onSend: () {},
              onPickImage: () => picks++,
              onPickFile: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Insert emoji'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('message-composer-bar'))).height,
      greaterThanOrEqualTo(RetroMetrics.composerBarHeight),
    );
    expect(
      tester.getSize(find.byKey(const Key('message-send-button'))),
      const Size.square(RetroMetrics.composerSendDiameter),
    );
    final barRect = tester.getRect(
      find.byKey(const Key('message-composer-bar')),
    );
    final attachmentRect = tester.getRect(
      find.byKey(const Key('message-attachment-button')),
    );
    final sendRect = tester.getRect(
      find.byKey(const Key('message-send-button')),
    );
    expect(
      attachmentRect.center.dx - barRect.left,
      RetroMetrics.composerCornerRadius,
    );
    expect(
      barRect.right - sendRect.center.dx,
      RetroMetrics.composerCornerRadius,
    );
    final attachmentIconRect = tester.getRect(find.byIcon(Icons.add_rounded));
    expect(
      attachmentIconRect.center.dx,
      moreOrLessEquals(attachmentRect.center.dx, epsilon: 0.1),
    );
    expect(
      attachmentIconRect.center.dy,
      moreOrLessEquals(attachmentRect.center.dy, epsilon: 0.1),
    );
    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    expect(find.text('Photo…'), findsOneWidget);
    expect(find.text('File…'), findsOneWidget);

    await tester.tap(find.text('Photo…'));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(find.text('Photo…'), findsNothing);

    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    expect(find.text('Photo…'), findsOneWidget);
  });

  testWidgets('attachment menu exposes file picking', (tester) async {
    var filePicks = 0;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MessageComposer(
              controller: controller,
              focusNode: focusNode,
              disabled: false,
              recipientName: 'Sam',
              onSend: () {},
              onPickImage: () {},
              onPickFile: () => filePicks++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File…'));
    await tester.pumpAndSettle();

    expect(filePicks, 1);
    expect(find.text('File…'), findsNothing);
  });

  testWidgets('uses Shift+Enter for a line break and Enter to send', (
    tester,
  ) async {
    var sent = 0;
    final controller = TextEditingController(text: 'First line');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: MessageComposer(
            controller: controller,
            focusNode: focusNode,
            disabled: false,
            recipientName: 'Sam',
            onSend: () => sent++,
            onPickImage: () {},
            onPickFile: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('message-composer')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(controller.text, 'First line\n');
    expect(sent, 0);
    expect(find.byKey(const Key('message-composer-expanded')), findsOneWidget);
    expect(find.byKey(const Key('message-composer-collapsed')), findsNothing);
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(controller.selection, const TextSelection.collapsed(offset: 11));
    final field = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(field.maxLines, RetroMetrics.composerMaxLines);

    final eightLines = List.generate(
      RetroMetrics.composerMaxLines,
      (index) => 'Line $index',
    ).join('\n');
    await tester.enterText(
      find.byKey(const Key('message-composer')),
      eightLines,
    );
    await tester.pump();
    final cappedHeight = tester
        .getSize(find.byKey(const Key('message-composer-bar')))
        .height;

    await tester.enterText(
      find.byKey(const Key('message-composer')),
      '$eightLines\nOverflow line',
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const Key('message-composer-bar'))).height,
      moreOrLessEquals(cappedHeight, epsilon: 1),
    );
    final decoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('message-composer-bar')),
                )
                .decoration!
            as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(RetroMetrics.composerCornerRadius),
    );
    final actions = find.byKey(const Key('message-composer-actions'));
    expect(actions, findsOneWidget);
    final barRect = tester.getRect(
      find.byKey(const Key('message-composer-bar')),
    );
    final sendRect = tester.getRect(
      find.byKey(const Key('message-send-button')),
    );
    final attachmentRect = tester.getRect(
      find.byKey(const Key('message-attachment-button')),
    );
    expect(
      barRect.right - sendRect.center.dx,
      RetroMetrics.composerCornerRadius,
    );
    expect(
      barRect.bottom - sendRect.center.dy,
      RetroMetrics.composerCornerRadius,
    );
    expect(
      sendRect.bottom,
      moreOrLessEquals(attachmentRect.bottom, epsilon: 0.1),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(sent, 1);
  });

  testWidgets('lets the input method confirm composing text before sending', (
    tester,
  ) async {
    var sent = 0;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: MessageComposer(
            controller: controller,
            focusNode: focusNode,
            disabled: false,
            recipientName: 'Sam',
            onSend: () => sent++,
            onPickImage: () {},
            onPickFile: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('message-composer')));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'にほんご',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(sent, 0);
    expect(controller.text, 'にほんご');

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '日本語',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(sent, 1);
  });

  testWidgets('moves actions below text when content wraps visually', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: 'This message wraps without an explicit line break.',
    );
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 320,
              child: MessageComposer(
                controller: controller,
                focusNode: focusNode,
                disabled: false,
                recipientName: 'Sam',
                onSend: () {},
                onPickImage: () {},
                onPickFile: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('message-composer-expanded')), findsOneWidget);
    expect(find.byKey(const Key('message-composer-actions')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('message-composer-actions'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('message-composer'))).dy,
      ),
    );
  });
}
