import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_launch_at_login.dart';

final launchAtLoginProvider =
    AsyncNotifierProvider.autoDispose<
      LaunchAtLoginNotifier,
      LaunchAtLoginState
    >(LaunchAtLoginNotifier.new);

class LaunchAtLoginState {
  const LaunchAtLoginState({required this.status, this.isUpdating = false});

  final LaunchAtLoginStatus status;
  final bool isUpdating;
}

class LaunchAtLoginNotifier extends AsyncNotifier<LaunchAtLoginState> {
  @override
  Future<LaunchAtLoginState> build() async {
    final status = await ref.watch(launchAtLoginPlatformProvider).getStatus();
    return LaunchAtLoginState(status: status);
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value;
    if (current == null || current.isUpdating) {
      return;
    }
    state = AsyncData(
      LaunchAtLoginState(status: current.status, isUpdating: true),
    );
    state = await AsyncValue.guard(() async {
      final status = await ref
          .read(launchAtLoginPlatformProvider)
          .setEnabled(enabled);
      return LaunchAtLoginState(status: status);
    });
  }
}

class LaunchAtLoginSetting extends ConsumerWidget {
  const LaunchAtLoginSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(launchAtLoginProvider);
    final launchState = value.value;
    final status = launchState?.status;
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch at login',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_supportingText(value, status) case final text?) ...[
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              key: const Key('launch-at-login-switch'),
              value: status == LaunchAtLoginStatus.enabled,
              onChanged: _canChange(value, launchState)
                  ? (enabled) => _setEnabled(context, ref, enabled)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canChange(
    AsyncValue<LaunchAtLoginState> value,
    LaunchAtLoginState? launchState,
  ) {
    return !value.isLoading &&
        !value.hasError &&
        launchState?.isUpdating != true &&
        launchState?.status != LaunchAtLoginStatus.unsupported;
  }

  String? _supportingText(
    AsyncValue<LaunchAtLoginState> value,
    LaunchAtLoginStatus? status,
  ) {
    if (value.hasError) {
      return 'Unable to update this setting.';
    }
    return switch (status) {
      LaunchAtLoginStatus.requiresApproval =>
        'Approval is required in System Settings.',
      LaunchAtLoginStatus.unsupported => 'Requires macOS 13 or later.',
      _ => null,
    };
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    await ref.read(launchAtLoginProvider.notifier).setEnabled(enabled);
    if (!context.mounted) {
      return;
    }
    final result = ref.read(launchAtLoginProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update Launch at login.')),
      );
    }
  }
}
