import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_message_translation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('instant_chat/message_translation-test');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps every translation language code to its display label', () {
    expect(
      {
        for (final language in MessageTranslationLanguage.fallbackValues)
          language.code: language.label,
      },
      {
        'en': 'English',
        'zh-Hans': 'Simplified Chinese',
        'ja': 'Japanese',
        'zh-Hant': 'Traditional Chinese',
        'es': 'Spanish',
        'en-GB': 'English (UK)',
        'fr': 'French',
        'ko': 'Korean',
      },
    );
  });

  test('parses languages returned by the current Mac', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getSupportedLanguages');
          return <Map<String, String>>[
            {'code': 'de', 'label': 'German'},
            {'code': 'cy', 'label': 'Welsh'},
          ];
        });
    const translation = MacOSMessageTranslation(channel);

    expect(await translation.getSupportedLanguages(), const [
      MessageTranslationLanguage('de', 'German'),
      MessageTranslationLanguage('cy', 'Welsh'),
    ]);
  });

  test('reads and saves the target language', () async {
    MethodCall? savedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getTargetLanguage') {
            return 'zh-Hans';
          }
          savedCall = call;
          return null;
        });
    const translation = MacOSMessageTranslation(channel);

    expect(
      await translation.getTargetLanguage(),
      MessageTranslationLanguage.simplifiedChinese,
    );
    await translation.setTargetLanguage(MessageTranslationLanguage.japanese);

    expect(savedCall?.method, 'setTargetLanguage');
    expect(savedCall?.arguments, 'ja');
  });

  test('sends text and the selected target language for translation', () async {
    MethodCall? translationCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          translationCall = call;
          return 'こんにちは。';
        });
    const translation = MacOSMessageTranslation(channel);

    final result = await translation.translate(
      text: 'Hello.',
      targetLanguage: MessageTranslationLanguage.japanese,
    );

    expect(result, 'こんにちは。');
    expect(translationCall?.method, 'translate');
    expect(translationCall?.arguments, {
      'text': 'Hello.',
      'target_language': 'ja',
    });
  });

  test(
    'reads, stores, and removes translations by account and conversation',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'getStoredTranslations') {
              return <String, String>{'42': '你好。'};
            }
            return null;
          });
      const translation = MacOSMessageTranslation(channel);

      final stored = await translation.getStoredTranslations(
        accountId: '7',
        conversationId: '11',
        targetLanguage: MessageTranslationLanguage.simplifiedChinese,
      );
      await translation.storeTranslation(
        accountId: '7',
        conversationId: '11',
        messageId: '43',
        targetLanguage: MessageTranslationLanguage.simplifiedChinese,
        translatedText: '再见。',
      );
      await translation.removeStoredTranslation(
        accountId: '7',
        conversationId: '11',
        messageId: '42',
        targetLanguage: MessageTranslationLanguage.simplifiedChinese,
      );

      expect(stored, {'42': '你好。'});
      expect(calls[0].method, 'getStoredTranslations');
      expect(calls[0].arguments, {
        'account_id': '7',
        'conversation_id': '11',
        'target_language': 'zh-Hans',
      });
      expect(calls[1].method, 'storeTranslation');
      expect(calls[1].arguments, {
        'account_id': '7',
        'conversation_id': '11',
        'message_id': '43',
        'target_language': 'zh-Hans',
        'translated_text': '再见。',
      });
      expect(calls[2].method, 'removeStoredTranslation');
      expect(calls[2].arguments, {
        'account_id': '7',
        'conversation_id': '11',
        'message_id': '42',
        'target_language': 'zh-Hans',
      });
    },
  );
}
