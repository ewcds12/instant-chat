import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/app-language-test');
  late MethodChannelAppLanguagePlatform platform;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getLanguage') {
            return 'ja';
          }
          return null;
        });
    platform = MethodChannelAppLanguagePlatform(channel: channel);
  });

  tearDown(() async {
    await platform.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the persisted language from macOS', () async {
    expect(await platform.getLanguage(), AppLanguage.japanese);
    expect(calls.single.method, 'getLanguage');
  });

  test('persists the selected language code through macOS', () async {
    await platform.setLanguage(AppLanguage.simplifiedChinese);

    expect(calls.single.method, 'setLanguage');
    expect(calls.single.arguments, {'code': 'zh-Hans'});
  });
}
