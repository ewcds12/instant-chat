import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_message_translation.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

enum MessageTranslationStatus { loading, translated, failed }

class MessageTranslationPresentation {
  const MessageTranslationPresentation._({
    required this.language,
    required this.status,
    this.text,
  });

  const MessageTranslationPresentation.loading(
    MessageTranslationLanguage language,
  ) : this._(language: language, status: MessageTranslationStatus.loading);

  const MessageTranslationPresentation.translated(
    MessageTranslationLanguage language,
    String text,
  ) : this._(
        language: language,
        status: MessageTranslationStatus.translated,
        text: text,
      );

  const MessageTranslationPresentation.failed(
    MessageTranslationLanguage language,
  ) : this._(language: language, status: MessageTranslationStatus.failed);

  final MessageTranslationLanguage language;
  final MessageTranslationStatus status;
  final String? text;
}

class MessageTranslationView extends StatelessWidget {
  const MessageTranslationView({
    required this.messageId,
    required this.translation,
    required this.isMine,
    super.key,
  });

  final String messageId;
  final MessageTranslationPresentation translation;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isMine
        ? colors.onPrimary.withValues(alpha: 0.82)
        : colors.onSurfaceVariant;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: foreground, height: 1.35);
    return Padding(
      key: ValueKey('message-translation-$messageId'),
      padding: const EdgeInsets.only(top: RetroMetrics.spaceSmall),
      child: switch (translation.status) {
        MessageTranslationStatus.loading => Row(
          key: ValueKey('message-translation-loading-$messageId'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: RetroMetrics.messageTranslationProgressSize,
              child: CircularProgressIndicator(
                strokeWidth: RetroMetrics.border * 1.5,
                color: foreground,
              ),
            ),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Flexible(
              child: Text(
                context.l10n.ui('Translating…'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
        MessageTranslationStatus.translated => Text(
          translation.text!,
          key: ValueKey('message-translation-text-$messageId'),
          style: style,
        ),
        MessageTranslationStatus.failed => Row(
          key: ValueKey('message-translation-failed-$messageId'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: RetroMetrics.messageTranslationStatusIconSize,
              color: foreground,
            ),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Flexible(
              child: Text(
                context.l10n.ui('Translation unavailable'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      },
    );
  }
}
