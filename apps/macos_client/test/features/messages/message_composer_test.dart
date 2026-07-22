import 'package:flutter/material.dart';
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
}
