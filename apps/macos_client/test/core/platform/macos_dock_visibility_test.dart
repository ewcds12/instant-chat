import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_dock_visibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/dock-visibility-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads and updates the Dock preference', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'getKeepAppInDock' ? false : null;
        });
    const platform = MacOSDockVisibilityPlatform(channel);

    expect(await platform.getKeepAppInDock(), isFalse);
    await platform.setKeepAppInDock(true);

    expect(calls.last.method, 'setKeepAppInDock');
    expect(calls.last.arguments, {'enabled': true});
  });

  test('keeps the app in Dock when no preference is stored', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    const platform = MacOSDockVisibilityPlatform(channel);

    expect(await platform.getKeepAppInDock(), isTrue);
  });
}
