import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';

class LanguageSetting extends ConsumerWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(appLanguageProvider);
    final language = preference.value ?? AppLanguage.english;
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<AppLanguage>(
      key: const Key('app-language-setting'),
      enabled: !preference.isLoading,
      tooltip: context.l10n.languageSettingLabel,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 240),
      onSelected: (selection) => _setLanguage(context, ref, selection),
      itemBuilder: (context) => [
        for (final option in AppLanguage.values)
          PopupMenuItem(
            key: Key('app-language-${option.platformCode}'),
            value: option,
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: option == language
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(option.nativeLabel),
              ],
            ),
          ),
      ],
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.languageSettingLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              language.nativeLabel,
              key: const Key('app-language-current-value'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
  ) async {
    try {
      await ref.read(appLanguageProvider.notifier).setLanguage(language);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.languageSettingUpdateFailed)),
      );
    }
  }
}
