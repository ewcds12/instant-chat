part of 'messages_page.dart';

extension _MessagesPageTranslation on _MessagesPageState {
  Future<void> _translateMessage(Message message) async {
    if (message.kind != MessageKind.text || message.body.trim().isEmpty) {
      return;
    }
    if (_messageTranslations[message.id]?.status ==
        MessageTranslationStatus.loading) {
      return;
    }
    final language = await _requireTranslationLanguage();
    if (!mounted || language == null) {
      return;
    }
    final translationService = ref.read(localMessageTranslationProvider);
    final accountId = ref
        .read(authControllerProvider)
        .requireValue
        .session!
        .user
        .id;
    final conversationId = widget.conversation.id;
    _updateTranslationState(() {
      _messageTranslations[message.id] = MessageTranslationPresentation.loading(
        language,
      );
    });
    try {
      final translatedText = await translationService.translate(
        text: message.body,
        targetLanguage: language,
      );
      if (mounted && widget.conversation.id == conversationId) {
        _updateTranslationState(() {
          _messageTranslations[message.id] =
              MessageTranslationPresentation.translated(
                language,
                translatedText,
              );
        });
      }
      try {
        await translationService.storeTranslation(
          accountId: accountId,
          conversationId: conversationId,
          messageId: message.id,
          targetLanguage: language,
          translatedText: translatedText,
        );
      } catch (_) {
        if (mounted && widget.conversation.id == conversationId) {
          _showSaveError(context.l10n.ui('Translation could not be saved.'));
        }
      }
    } catch (_) {
      if (!mounted || widget.conversation.id != conversationId) {
        return;
      }
      _updateTranslationState(() {
        _messageTranslations[message.id] =
            MessageTranslationPresentation.failed(language);
      });
    }
  }

  Future<void> _openTranslationSettings() async {
    final currentLanguage = await _loadTranslationLanguage();
    if (!mounted) {
      return;
    }
    await _chooseTranslationLanguage(
      currentLanguage: currentLanguage,
      selectionRequired: false,
    );
  }

  Future<void> _removeMessageTranslation(Message message) async {
    final translation = _messageTranslations[message.id];
    if (translation?.status != MessageTranslationStatus.translated) {
      return;
    }
    final conversationId = widget.conversation.id;
    final accountId = ref
        .read(authControllerProvider)
        .requireValue
        .session!
        .user
        .id;
    _updateTranslationState(() {
      _messageTranslations.remove(message.id);
    });
    try {
      await ref
          .read(localMessageTranslationProvider)
          .removeStoredTranslation(
            accountId: accountId,
            conversationId: conversationId,
            messageId: message.id,
            targetLanguage: translation!.language,
          );
    } catch (_) {
      if (!mounted || widget.conversation.id != conversationId) {
        return;
      }
      _updateTranslationState(() {
        _messageTranslations.putIfAbsent(message.id, () => translation!);
      });
      _showSaveError(context.l10n.ui('Translation could not be removed.'));
    }
  }

  Future<MessageTranslationLanguage?> _requireTranslationLanguage() async {
    final currentLanguage = await _loadTranslationLanguage();
    if (!mounted || currentLanguage != null) {
      return currentLanguage;
    }
    return _chooseTranslationLanguage(
      currentLanguage: null,
      selectionRequired: true,
    );
  }

  Future<MessageTranslationLanguage?> _loadTranslationLanguage() async {
    if (_translationLanguageLoaded) {
      return _translationLanguage;
    }
    try {
      _translationLanguage = await ref
          .read(localMessageTranslationProvider)
          .getTargetLanguage();
    } catch (_) {
      _translationLanguage = null;
    }
    _translationLanguageLoaded = true;
    return _translationLanguage;
  }

  Future<MessageTranslationLanguage?> _chooseTranslationLanguage({
    required MessageTranslationLanguage? currentLanguage,
    required bool selectionRequired,
  }) async {
    var languages = MessageTranslationLanguage.fallbackValues;
    try {
      final supported = await ref
          .read(localMessageTranslationProvider)
          .getSupportedLanguages();
      if (supported.isNotEmpty) {
        languages = supported;
      }
    } catch (_) {
      languages = MessageTranslationLanguage.fallbackValues;
    }
    if (!mounted) {
      return null;
    }
    final selected = await showMessageTranslationLanguageDialog(
      context: context,
      currentLanguage: currentLanguage,
      languages: languages,
      selectionRequired: selectionRequired,
    );
    if (!mounted || selected == null) {
      return null;
    }
    _updateTranslationState(() {
      _translationLanguage = selected;
      _translationLanguageLoaded = true;
      _messageTranslations.clear();
    });
    try {
      await ref
          .read(localMessageTranslationProvider)
          .setTargetLanguage(selected);
    } catch (_) {
      if (mounted) {
        _showSaveError(
          context.l10n.ui('Translation preference could not be saved.'),
        );
      }
    }
    await _restoreStoredTranslations(language: selected);
    return selected;
  }

  Future<void> _restoreStoredTranslations({
    MessageTranslationLanguage? language,
  }) async {
    final selectedLanguage = language ?? await _loadTranslationLanguage();
    if (!mounted || selectedLanguage == null) {
      return;
    }
    final conversationId = widget.conversation.id;
    final accountId = ref
        .read(authControllerProvider)
        .requireValue
        .session!
        .user
        .id;
    try {
      final stored = await ref
          .read(localMessageTranslationProvider)
          .getStoredTranslations(
            accountId: accountId,
            conversationId: conversationId,
            targetLanguage: selectedLanguage,
          );
      if (!mounted ||
          widget.conversation.id != conversationId ||
          _translationLanguage != selectedLanguage) {
        return;
      }
      _updateTranslationState(() {
        for (final entry in stored.entries) {
          if (entry.value.trim().isEmpty) {
            continue;
          }
          _messageTranslations.putIfAbsent(
            entry.key,
            () => MessageTranslationPresentation.translated(
              selectedLanguage,
              entry.value,
            ),
          );
        }
      });
    } catch (_) {
      return;
    }
  }
}
