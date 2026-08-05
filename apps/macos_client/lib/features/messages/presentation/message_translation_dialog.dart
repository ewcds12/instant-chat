import 'package:flutter/material.dart';
import 'package:instant_chat/core/platform/macos_message_translation.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

Future<MessageTranslationLanguage?> showMessageTranslationLanguageDialog({
  required BuildContext context,
  required MessageTranslationLanguage? currentLanguage,
  required bool selectionRequired,
}) {
  return showDialog<MessageTranslationLanguage>(
    context: context,
    barrierDismissible: !selectionRequired,
    builder: (context) => PopScope(
      canPop: !selectionRequired,
      child: AlertDialog(
        key: const Key('message-translation-language-dialog'),
        title: const Text('Translate to'),
        contentPadding: const EdgeInsets.fromLTRB(
          RetroMetrics.spaceLarge,
          RetroMetrics.spaceSmall,
          RetroMetrics.spaceLarge,
          RetroMetrics.spaceSmall,
        ),
        content: SizedBox(
          width: RetroMetrics.messageTranslationDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final language in MessageTranslationLanguage.values)
                _LanguageOption(
                  language: language,
                  selected: language == currentLanguage,
                ),
            ],
          ),
        ),
        actions: selectionRequired
            ? null
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
      ),
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.language, required this.selected});

  final MessageTranslationLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      key: ValueKey('message-translation-language-${language.code}'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.spaceSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      title: Text(language.label),
      trailing: selected
          ? Icon(Icons.check_rounded, size: 18, color: colors.primary)
          : null,
      onTap: () => Navigator.pop(context, language),
    );
  }
}
