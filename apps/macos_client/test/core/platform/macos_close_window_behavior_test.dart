import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_close_window_behavior.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/close-window-behavior-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads and updates the close-window behavior', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'getBehavior' ? 'quit_application' : null;
        });
    const platform = MacOSCloseWindowBehaviorPlatform(channel);

    expect(await platform.getBehavior(), CloseWindowBehavior.quitApplication);
    await platform.setBehavior(CloseWindowBehavior.keepRunning);

    expect(calls.last.method, 'setBehavior');
    expect(calls.last.arguments, {'behavior': 'keep_running'});
  });

  test('keeps running when no preference is stored', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    const platform = MacOSCloseWindowBehaviorPlatform(channel);

    expect(await platform.getBehavior(), CloseWindowBehavior.keepRunning);
  });
}
