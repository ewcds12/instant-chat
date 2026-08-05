import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localMessageTranslationProvider = Provider<LocalMessageTranslation>((
  ref,
) {
  return MacOSMessageTranslation();
});

enum MessageTranslationLanguage {
  english('en', 'English'),
  simplifiedChinese('zh-Hans', 'Simplified Chinese'),
  japanese('ja', 'Japanese');

  const MessageTranslationLanguage(this.code, this.label);

  final String code;
  final String label;

  static MessageTranslationLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) {
        return language;
      }
    }
    return null;
  }
}

abstract interface class LocalMessageTranslation {
  Future<MessageTranslationLanguage?> getTargetLanguage();

  Future<void> setTargetLanguage(MessageTranslationLanguage language);

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
}
