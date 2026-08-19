import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';

final openLinksInDefaultBrowserProvider =
    AsyncNotifierProvider.autoDispose<OpenLinksNotifier, bool>(
      OpenLinksNotifier.new,
    );

class OpenLinksNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref
        .watch(linkOpeningPreferenceProvider)
        .getOpenLinksInDefaultBrowser();
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.isLoading) {
      return;
    }
    final previous = state.value ?? true;
    state = AsyncData(enabled);
    try {
      await ref
          .read(linkOpeningPreferenceProvider)
          .setOpenLinksInDefaultBrowser(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class OpenLinksSetting extends ConsumerWidget {
  const OpenLinksSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(openLinksInDefaultBrowserProvider);
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Open links in default browser',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              key: const Key('open-links-in-default-browser-switch'),
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
      await ref
          .read(openLinksInDefaultBrowserProvider.notifier)
          .setEnabled(enabled);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update link settings.')),
      );
    }
  }
}
