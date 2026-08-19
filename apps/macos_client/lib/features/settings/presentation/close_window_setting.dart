import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_close_window_behavior.dart';

final closeWindowBehaviorProvider =
    AsyncNotifierProvider.autoDispose<
      CloseWindowBehaviorNotifier,
      CloseWindowBehavior
    >(CloseWindowBehaviorNotifier.new);

class CloseWindowBehaviorNotifier extends AsyncNotifier<CloseWindowBehavior> {
  @override
  Future<CloseWindowBehavior> build() {
    return ref.watch(closeWindowBehaviorPlatformProvider).getBehavior();
  }

  Future<void> setBehavior(CloseWindowBehavior behavior) async {
    if (state.isLoading) {
      return;
    }
    final previous = state.value ?? CloseWindowBehavior.keepRunning;
    state = AsyncData(behavior);
    try {
      await ref.read(closeWindowBehaviorPlatformProvider).setBehavior(behavior);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class CloseWindowSetting extends ConsumerWidget {
  const CloseWindowSetting({super.key});

  static const _labels = {
    CloseWindowBehavior.keepRunning: 'Keep Instant Chat running',
    CloseWindowBehavior.quitApplication: 'Quit Instant Chat',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(closeWindowBehaviorProvider);
    final behavior = preference.value ?? CloseWindowBehavior.keepRunning;
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<CloseWindowBehavior>(
      key: const Key('close-window-setting'),
      enabled: !preference.isLoading,
      tooltip: 'Choose what happens when the window closes',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 380, maxWidth: 400),
      onSelected: (selection) => _setBehavior(context, ref, selection),
      itemBuilder: (context) => [
        for (final option in CloseWindowBehavior.values)
          PopupMenuItem(
            key: Key('close-window-${option.platformValue}'),
            value: option,
            height: 42,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: option == behavior
                      ? Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: colors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(_labels[option]!),
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
                'Close window',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Text(
              _labels[behavior]!,
              key: const Key('close-window-current-value'),
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

  Future<void> _setBehavior(
    BuildContext context,
    WidgetRef ref,
    CloseWindowBehavior behavior,
  ) async {
    try {
      await ref
          .read(closeWindowBehaviorProvider.notifier)
          .setBehavior(behavior);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update close-window settings.'),
        ),
      );
    }
  }
}
