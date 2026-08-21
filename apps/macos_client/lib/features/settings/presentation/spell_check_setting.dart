import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_spell_check.dart';

class SpellCheckSetting extends ConsumerWidget {
  const SpellCheckSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(spellCheckEnabledProvider);
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.checkSpelling,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              key: const Key('check-spelling-switch'),
              value: preference.value ?? true,
              onChanged: preference.isLoading
                  ? null
                  : (enabled) => _setEnabled(context, ref, enabled),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref.read(spellCheckEnabledProvider.notifier).setEnabled(enabled);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unableToUpdateSetting)),
      );
    }
  }
}
