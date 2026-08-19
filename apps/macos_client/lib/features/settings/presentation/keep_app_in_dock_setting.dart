import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_dock_visibility.dart';

final keepAppInDockProvider =
    AsyncNotifierProvider.autoDispose<KeepAppInDockNotifier, bool>(
      KeepAppInDockNotifier.new,
    );

class KeepAppInDockNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(dockVisibilityPlatformProvider).getKeepAppInDock();
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.isLoading) {
      return;
    }
    final previous = state.value ?? true;
    state = AsyncData(enabled);
    try {
      await ref.read(dockVisibilityPlatformProvider).setKeepAppInDock(enabled);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class KeepAppInDockSetting extends ConsumerWidget {
  const KeepAppInDockSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(keepAppInDockProvider);
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Keep app in Dock',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              key: const Key('keep-app-in-dock-switch'),
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
      await ref.read(keepAppInDockProvider.notifier).setEnabled(enabled);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update Dock settings.')),
      );
    }
  }
}
