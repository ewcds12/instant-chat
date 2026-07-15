import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/system_status/domain/service_health.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_provider.dart';

class SystemStatusPage extends ConsumerWidget {
  const SystemStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(serviceHealthProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RetroMetrics.maxPanelWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(
                    color: colors.onSurface,
                    width: RetroMetrics.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onSurface,
                      offset: const Offset(
                        RetroMetrics.spaceSmall,
                        RetroMetrics.spaceSmall,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TitleBar(colors: colors),
                    Padding(
                      padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONNECTION TERMINAL',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: RetroMetrics.spaceSmall),
                          const Text(
                            'Instant Chat macOS client // local development link',
                          ),
                          const SizedBox(height: RetroMetrics.spaceLarge),
                          health.when(
                            loading: () => _StatusPanel.loading(colors),
                            error: (_, _) => _StatusPanel.offline(colors),
                            data: (value) =>
                                _StatusPanel.fromHealth(colors, value),
                          ),
                          const SizedBox(height: RetroMetrics.spaceLarge),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.invalidate(serviceHealthProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('RETRY CONNECTION'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.onSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.spaceMedium,
        vertical: RetroMetrics.spaceSmall,
      ),
      child: Text(
        'INSTANT CHAT // SYSTEM STATUS',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colors.surface),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.label,
    required this.detail,
    required this.color,
    required this.icon,
  });

  factory _StatusPanel.loading(ColorScheme colors) {
    return _StatusPanel(
      label: 'DIALING...',
      detail: '正在连接本地 API',
      color: colors.secondary,
      icon: Icons.hourglass_top,
    );
  }

  factory _StatusPanel.offline(ColorScheme colors) {
    return _StatusPanel(
      label: 'OFFLINE',
      detail: '无法连接本地 API，请确认服务已启动',
      color: colors.error,
      icon: Icons.link_off,
    );
  }

  factory _StatusPanel.fromHealth(ColorScheme colors, ServiceHealth health) {
    if (!health.isHealthy) {
      return _StatusPanel(
        label: 'DEGRADED',
        detail: 'API 已连接，但数据库当前不可用',
        color: colors.secondary,
        icon: Icons.warning_amber,
      );
    }
    return _StatusPanel(
      label: 'ONLINE',
      detail:
          'API 与 MySQL 均正常 // ${health.checkedAt.toUtc().toIso8601String()}',
      color: colors.primary,
      icon: Icons.link,
    );
  }

  final String label;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'API status $label',
      child: Container(
        padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: RetroMetrics.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: RetroMetrics.statusIconSize),
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
                  const SizedBox(height: RetroMetrics.spaceSmall),
                  Text(detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
