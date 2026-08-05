import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localMessageTranslationProvider = Provider<LocalMessageTranslation>((
  ref,
) {
  return MacOSMessageTranslation();
});

class MessageTranslationLanguage {
  const MessageTranslationLanguage(this.code, this.label);

  static const english = MessageTranslationLanguage('en', 'English');
  static const simplifiedChinese = MessageTranslationLanguage(
    'zh-Hans',
    'Simplified Chinese',
  );
  static const japanese = MessageTranslationLanguage('ja', 'Japanese');
  static const traditionalChinese = MessageTranslationLanguage(
    'zh-Hant',
    'Traditional Chinese',
  );
  static const spanish = MessageTranslationLanguage('es', 'Spanish');
  static const britishEnglish = MessageTranslationLanguage(
    'en-GB',
    'English (UK)',
  );
  static const french = MessageTranslationLanguage('fr', 'French');
  static const korean = MessageTranslationLanguage('ko', 'Korean');
  static const fallbackValues = [
    english,
    simplifiedChinese,
    japanese,
    traditionalChinese,
    spanish,
    britishEnglish,
    french,
    korean,
  ];

  final String code;
  final String label;

  static MessageTranslationLanguage? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    for (final language in fallbackValues) {
      if (language.code == code) {
        return language;
      }
    }
    return MessageTranslationLanguage(code, code);
  }

  @override
  bool operator ==(Object other) =>
      other is MessageTranslationLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

abstract interface class LocalMessageTranslation {
  Future<MessageTranslationLanguage?> getTargetLanguage();

  Future<void> setTargetLanguage(MessageTranslationLanguage language);

  Future<List<MessageTranslationLanguage>> getSupportedLanguages();

  Future<Map<String, String>> getStoredTranslations({
    required String accountId,
    required String conversationId,
    required MessageTranslationLanguage targetLanguage,
  });

  Future<void> storeTranslation({
    required String accountId,
    required String conversationId,
    required String messageId,
    required MessageTranslationLanguage targetLanguage,
    required String translatedText,
  });

  Future<void> removeStoredTranslation({
    required String accountId,
    required String conversationId,
    required String messageId,
    required MessageTranslationLanguage targetLanguage,
  });

  Future<String> translate({
    required String text,
    required MessageTranslationLanguage targetLanguage,
  });
}

class MacOSMessageTranslation implements LocalMessageTranslation {
  const MacOSMessageTranslation([
    this._channel = const MethodChannel('instant_chat/message_translation'),
  ]);

  final MethodChannel _channel;

  @override
  Future<MessageTranslationLanguage?> getTargetLanguage() async {
    final code = await _channel.invokeMethod<String>('getTargetLanguage');
    return MessageTranslationLanguage.fromCode(code);
  }

  @override
  Future<void> setTargetLanguage(MessageTranslationLanguage language) {
    return _channel.invokeMethod<void>('setTargetLanguage', language.code);
  }

  @override
  Future<List<MessageTranslationLanguage>> getSupportedLanguages() async {
    final result = await _channel.invokeListMethod<Object?>(
      'getSupportedLanguages',
    );
    if (result == null) {
      throw const FormatException(
        'Supported translation languages are invalid.',
      );
    }
    return [for (final entry in result) _parseSupportedLanguage(entry)];
  }

  @override
  Future<Map<String, String>> getStoredTranslations({
    required String accountId,
    required String conversationId,
    required MessageTranslationLanguage targetLanguage,
  }) async {
    final translations = await _channel
        .invokeMapMethod<String, String>('getStoredTranslations', {
          'account_id': accountId,
          'conversation_id': conversationId,
          'target_language': targetLanguage.code,
        });
    return translations ?? const {};
  }

  @override
  Future<void> storeTranslation({
    required String accountId,
    required String conversationId,
    required String messageId,
    required MessageTranslationLanguage targetLanguage,
    required String translatedText,
  }) {
    return _channel.invokeMethod<void>('storeTranslation', {
      'account_id': accountId,
      'conversation_id': conversationId,
      'message_id': messageId,
      'target_language': targetLanguage.code,
      'translated_text': translatedText,
    });
  }

  @override
  Future<void> removeStoredTranslation({
    required String accountId,
    required String conversationId,
    required String messageId,
    required MessageTranslationLanguage targetLanguage,
  }) {
    return _channel.invokeMethod<void>('removeStoredTranslation', {
      'account_id': accountId,
      'conversation_id': conversationId,
      'message_id': messageId,
      'target_language': targetLanguage.code,
    });
  }

  @override
  Future<String> translate({
    required String text,
    required MessageTranslationLanguage targetLanguage,
  }) async {
    final translatedText = await _channel.invokeMethod<String>('translate', {
      'text': text,
      'target_language': targetLanguage.code,
    });
    if (translatedText == null || translatedText.trim().isEmpty) {
      throw const FormatException('Translation response is invalid.');
    }
    return translatedText;
  }

  MessageTranslationLanguage _parseSupportedLanguage(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Translation language entry is invalid.');
    }
    final code = value['code'];
    final label = value['label'];
    if (code is! String ||
        code.trim().isEmpty ||
        label is! String ||
        label.trim().isEmpty) {
      throw const FormatException('Translation language entry is invalid.');
    }
    return MessageTranslationLanguage(code, label);
  }
}
