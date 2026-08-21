import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_spell_check.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/spell-check-test');
  late MethodChannelSpellCheckPlatform platform;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getEnabled' => false,
            'check' => [
              {
                'startIndex': 0,
                'endIndex': 4,
                'suggestions': ['word'],
              },
            ],
            _ => null,
          };
        });
    platform = MethodChannelSpellCheckPlatform(channel: channel);
  });

  tearDown(() async {
    await platform.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads and persists the spelling preference', () async {
    expect(await platform.getEnabled(), isFalse);
    await platform.setEnabled(true);

    expect(calls.last.method, 'setEnabled');
    expect(calls.last.arguments, {'enabled': true});
  });

  test('maps native misspellings to suggestion spans', () async {
    final suggestions = await platform.fetchSpellCheckSuggestions(
      const Locale('en'),
      'wrod',
    );

    expect(suggestions, hasLength(1));
    expect(suggestions!.single.range, const TextRange(start: 0, end: 4));
    expect(suggestions.single.suggestions, ['word']);
    expect(calls.single.arguments, {'language': 'en', 'text': 'wrod'});
  });
}
