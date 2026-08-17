import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/news/domain/daily_brief.dart';
import 'package:instant_chat/features/news/presentation/daily_news_provider.dart';

class DailyBriefRail extends ConsumerWidget {
  const DailyBriefRail({required this.accessToken, super.key});

  final String accessToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DailyBriefPanel(
      brief: ref.watch(dailyBriefProvider(accessToken)),
      onRetry: () => ref.invalidate(dailyBriefProvider(accessToken)),
      onOpen: (url) => _open(context, ref, url),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Uri url) async {
    try {
      await ref.read(localUrlLauncherProvider).open(url);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The news link could not be opened.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class DailyBriefPanel extends StatelessWidget {
  const DailyBriefPanel({
    required this.brief,
    required this.onRetry,
    required this.onOpen,
    super.key,
  });

  final AsyncValue<DailyBrief> brief;
  final VoidCallback onRetry;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(RetroMetrics.dailyBriefInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Daily Brief', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: RetroMetrics.spaceSmall / 2),
            Text('Today', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: RetroMetrics.spaceMedium),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: RetroMetrics.spaceSmall),
            Expanded(
              child: brief.when(
                data: _content,
                error: _error,
                loading: _loading,
              ),
            ),
            Divider(color: colors.outlineVariant),
            _Attribution(onOpen: onOpen),
          ],
        ),
      ),
    );
  }

  Widget _content(DailyBrief value) {
    if (value.items.isEmpty) {
      return const Center(child: Text('No headlines are available today.'));
    }
    return Builder(
      builder: (context) => ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: value.items.length,
          itemBuilder: (context, index) {
            final item = value.items[index];
            return ConstrainedBox(
              key: ValueKey('daily-news-${item.id}'),
              constraints: const BoxConstraints(
                minHeight: RetroMetrics.dailyBriefItemMinHeight,
              ),
              child: _NewsRow(item: item, onOpen: onOpen),
            );
          },
          separatorBuilder: (context, index) =>
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _error(Object error, StackTrace stackTrace) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Daily news is unavailable.', textAlign: TextAlign.center),
          const SizedBox(height: RetroMetrics.spaceSmall),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator());
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.item, required this.onOpen});

  final DailyNewsItem item;
  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Open ${item.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        onTap: () => onOpen(item.url),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: RetroMetrics.spaceSmall,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              if (item.summary.isNotEmpty) ...[
                const SizedBox(height: RetroMetrics.spaceSmall / 2),
                Text(
                  item.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.onOpen});

  final ValueChanged<Uri> onOpen;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          overlayColor: Colors.transparent,
        ),
        onPressed: () => onOpen(
          Uri.parse('https://en.wikipedia.org/wiki/Portal:Current_events'),
        ),
        icon: const Icon(
          Icons.open_in_new,
          size: RetroMetrics.dailyBriefFooterIconSize,
        ),
        label: const Text('From Wikipedia'),
      ),
    );
  }
}
