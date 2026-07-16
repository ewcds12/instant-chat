import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_provider.dart';

class SystemStatusPage extends ConsumerWidget {
  const SystemStatusPage({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(serviceHealthProvider);
    final colors = Theme.of(context).colorScheme;
    return LiquidGradientBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: RetroMetrics.maxPanelWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'System',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: RetroMetrics.spaceSmall),
                Text(
                  'Connection status for the Instant Chat service.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: RetroMetrics.spaceLarge),
                health.when(
                  loading: () => _StatusCard.loading(colors),
                  error: (_, _) => _StatusCard.offline(colors),
                  data: (value) => _StatusCard.fromHealth(colors, value),
                ),
                const SizedBox(height: RetroMetrics.spaceMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: RetroMetrics.spaceSmall,
                    runSpacing: RetroMetrics.spaceSmall,
                    children: [
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(serviceHealthProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 19),
                        label: const Text('Check again'),
                      ),
                      TextButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded, size: 19),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.detail,
    required this.color,
    required this.icon,
  });

  factory _StatusCard.loading(ColorScheme colors) {
    return _StatusCard(
      label: 'Connecting',
      detail: 'Checking the local API and database.',
      color: colors.primary,
      icon: Icons.sync_rounded,
    );
  }

  factory _StatusCard.offline(ColorScheme colors) {
    return _StatusCard(
      label: 'Offline',
      detail:
          'The local API could not be reached. Make sure the service is running.',
      color: colors.error,
      icon: Icons.cloud_off_outlined,
    );
  }

  factory _StatusCard.fromHealth(ColorScheme colors, ServiceHealth health) {
    if (!health.isHealthy) {
      return _StatusCard(
        label: 'Service degraded',
        detail: 'The API is available, but the database is unavailable.',
        color: colors.error,
        icon: Icons.warning_amber_rounded,
      );
    }
    return _StatusCard(
      label: 'Online',
      detail:
          'The API and MySQL are operational. Last checked ${_time(health.checkedAt)}.',
      color: colors.primary,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  final String label;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'API status $label',
      child: GlassPanel(
        tint: RetroColors.glassStrong,
        padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(RetroMetrics.corner),
              ),
              child: Icon(
                icon,
                color: color,
                size: RetroMetrics.statusIconSize,
              ),
            ),
            const SizedBox(width: RetroMetrics.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _time(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
