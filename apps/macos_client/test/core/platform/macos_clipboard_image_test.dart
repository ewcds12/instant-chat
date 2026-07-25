import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_clipboard_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads and releases a temporary clipboard image', () async {
    final directory = await Directory.systemTemp.createTemp(
      'instant-chat-clipboard-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final imageFile = File('${directory.path}/copied.png');
    await imageFile.writeAsBytes([1, 2, 3]);
    const channel = MethodChannel('instant_chat/clipboard-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'readImage');
          return {'path': imageFile.path, 'is_temporary': true};
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final clipboard = MacOSClipboardImage(channel);
    addTearDown(clipboard.dispose);

    final image = await clipboard.read();

    expect(image?.path, imageFile.path);
    expect(image?.isTemporary, isTrue);
    await clipboard.release(image!);
    expect(await imageFile.exists(), isFalse);
  });

  test('emits an image pasted by the native window', () async {
    const channel = MethodChannel('instant_chat/clipboard-event-test');
    final clipboard = MacOSClipboardImage(channel);
    addTearDown(clipboard.dispose);
    final received = clipboard.pastedImages.first;

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            const MethodCall('imagePasted', {
              'path': '/tmp/native-paste.png',
              'is_temporary': true,
            }),
          ),
          (_) {},
        );

    final image = await received;
    expect(image.path, '/tmp/native-paste.png');
    expect(image.isTemporary, isTrue);
  });
}
