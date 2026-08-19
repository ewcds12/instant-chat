import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/url-launcher-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('opens web links through the native launcher', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });
    const launcher = MacOSUrlLauncher(channel);

    await launcher.open(Uri.parse('https://example.com/news'));

    expect(receivedCall?.method, 'open');
    expect(receivedCall?.arguments, {'url': 'https://example.com/news'});
  });

  test('rejects non-web links before calling the platform', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          calls += 1;
          return null;
        });
    const launcher = MacOSUrlLauncher(channel);

    await expectLater(
      launcher.open(Uri.parse('file:///tmp/private.txt')),
      throwsArgumentError,
    );
    expect(calls, 0);
  });

  test('reads and updates the default-browser preference', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'getOpenLinksInDefaultBrowser' ? false : null;
        });
    const launcher = MacOSUrlLauncher(channel);

    expect(await launcher.getOpenLinksInDefaultBrowser(), isFalse);
    await launcher.setOpenLinksInDefaultBrowser(true);

    expect(calls.last.method, 'setOpenLinksInDefaultBrowser');
    expect(calls.last.arguments, {'enabled': true});
  });

  test('defaults to the system browser when no preference is stored', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    const launcher = MacOSUrlLauncher(channel);

    expect(await launcher.getOpenLinksInDefaultBrowser(), isTrue);
  });
}
