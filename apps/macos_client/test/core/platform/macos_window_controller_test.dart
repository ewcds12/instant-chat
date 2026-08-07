import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_window_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/window-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends compact authentication and expanded main window modes', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    const controller = MacOSAppWindowController(channel);

    await controller.setMode(AppWindowMode.authentication);
    await controller.setMode(AppWindowMode.main);

    expect(calls, hasLength(2));
    expect(calls[0].method, 'setMode');
    expect(calls[0].arguments, 'authentication');
    expect(calls[1].method, 'setMode');
    expect(calls[1].arguments, 'main');
  });
}
