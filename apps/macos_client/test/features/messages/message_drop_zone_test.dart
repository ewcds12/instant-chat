import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/messages/presentation/message_drop_zone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows drop feedback and returns dropped files', (tester) async {
    List<MessageDroppedFile>? droppedFiles;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageDropZone(
            disabled: false,
            onFiles: (files) async => droppedFiles = files,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    await _invokePlatformMethod(const MethodCall('entered', [20.0, 20.0]));
    await tester.pump();
    expect(find.byKey(const Key('message-drop-overlay')), findsOneWidget);
    expect(find.text('Release to send'), findsOneWidget);

    await _invokePlatformMethod(
      MethodCall('performOperation_macos', [
        {
          'path': '/tmp/photo.png',
          'apple-bookmark': Uint8List(0),
          'isDirectory': false,
          'fromPromise': false,
        },
      ]),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('message-drop-overlay')), findsNothing);
    expect(droppedFiles, hasLength(1));
    expect(droppedFiles!.single.path, '/tmp/photo.png');
    expect(droppedFiles!.single.isDirectory, isFalse);
  });

  testWidgets('does not react while disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageDropZone(
            disabled: true,
            onFiles: (_) async {},
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    await _invokePlatformMethod(const MethodCall('entered', [20.0, 20.0]));
    await tester.pump();

    expect(find.byKey(const Key('message-drop-overlay')), findsNothing);
  });
}

Future<void> _invokePlatformMethod(MethodCall call) async {
  final completer = Completer<ByteData?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'desktop_drop',
        const StandardMethodCodec().encodeMethodCall(call),
        completer.complete,
      );
  await completer.future;
}
