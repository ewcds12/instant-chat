import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class PostDetailHeader extends StatelessWidget {
  const PostDetailHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RetroMetrics.postDetailHeaderHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            IconButton(
              key: const Key('post-detail-back'),
              tooltip: context.l10n.ui('Back to Explore'),
              visualDensity: VisualDensity.compact,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
            ),
            const SizedBox(width: 3),
            Text(
              context.l10n.ui('Post'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class PostCommentsLabel extends StatelessWidget {
  const PostCommentsLabel({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: RetroMetrics.exploreContentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 3),
          child: Text(
            context.l10n.commentCount(count),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
