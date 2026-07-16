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
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add photo'));
    await tester.pumpAndSettle();
    expect(find.text('Photo…'), findsOneWidget);

    await tester.tap(find.text('Photo…'));
    await tester.pumpAndSettle();
    expect(picks, 1);
    expect(find.text('Photo…'), findsNothing);

    await tester.tap(find.byTooltip('Add photo'));
    await tester.pumpAndSettle();
    expect(find.text('Photo…'), findsOneWidget);
  });
}
