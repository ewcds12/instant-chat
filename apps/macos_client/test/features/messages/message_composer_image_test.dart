import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';

void main() {
  testWidgets('shows a pasted image and removes it from the composer', (
    tester,
  ) async {
    var removed = false;
    await _pumpComposer(
      tester,
      imagePath: '/tmp/copied-image.png',
      onRemoveImage: () => removed = true,
    );

    expect(
      find.byKey(const Key('message-composer-image-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('message-composer-expanded')), findsOneWidget);

    await tester.tap(find.byKey(const Key('message-composer-image-remove')));

    expect(removed, isTrue);
  });

  testWidgets('uses Command+V for image paste before plain text paste', (
    tester,
  ) async {
    var imagePasteCount = 0;
    await _pumpComposer(
      tester,
      onPasteImage: () async {
        imagePasteCount++;
        return true;
      },
    );
    await tester.tap(find.byKey(const Key('message-composer')));

    await _pressPaste(tester);
    await tester.pump();

    expect(imagePasteCount, 1);
    final field = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('keeps plain text clipboard paste working', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': 'Pasted text'};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _pumpComposer(tester, onPasteImage: () async => false);
    await tester.tap(find.byKey(const Key('message-composer')));

    await _pressPaste(tester);
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('message-composer')),
    );
    expect(field.controller?.text, 'Pasted text');
  });
}

Future<void> _pressPaste(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

Future<void> _pumpComposer(
  WidgetTester tester, {
  String? imagePath,
  VoidCallback? onRemoveImage,
  Future<bool> Function()? onPasteImage,
}) async {
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
            onPickFile: () {},
            imagePath: imagePath,
            onRemoveImage: onRemoveImage,
            onPasteImage: onPasteImage,
          ),
        ),
      ),
    ),
  );
}
