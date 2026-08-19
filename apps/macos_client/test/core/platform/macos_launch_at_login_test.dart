import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_launch_at_login.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/launch-at-login-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads and updates the native launch-at-login status', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'getStatus' ? 'disabled' : 'enabled';
        });
    const platform = MacOSLaunchAtLoginPlatform(channel);

    expect(await platform.getStatus(), LaunchAtLoginStatus.disabled);
    expect(await platform.setEnabled(true), LaunchAtLoginStatus.enabled);
    expect(calls, hasLength(2));
    expect(calls.first.method, 'getStatus');
    expect(calls.last.method, 'setEnabled');
    expect(calls.last.arguments, {'enabled': true});
  });

  test('rejects an unknown native status', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'unexpected');
    const platform = MacOSLaunchAtLoginPlatform(channel);

    await expectLater(platform.getStatus(), throwsStateError);
  });

  test('maps non-binary native states', () {
    expect(
      LaunchAtLoginStatus.fromPlatform('requires_approval'),
      LaunchAtLoginStatus.requiresApproval,
    );
    expect(
      LaunchAtLoginStatus.fromPlatform('unavailable'),
      LaunchAtLoginStatus.unavailable,
    );
    expect(
      LaunchAtLoginStatus.fromPlatform('unsupported'),
      LaunchAtLoginStatus.unsupported,
    );
  });
}
