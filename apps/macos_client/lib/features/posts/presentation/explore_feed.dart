import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/explore_header.dart';

List<PublicPost> filterExplorePosts(
  List<PublicPost> posts, {
  required ExploreFeedTab selectedTab,
  required Set<String> contactUserIds,
}) {
  return posts
      .where((post) {
        if (selectedTab == ExploreFeedTab.contacts &&
            !contactUserIds.contains(post.author.id)) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

PublicPost? findExplorePost(List<PublicPost> posts, String? id) {
  if (id == null) return null;
  for (final post in posts) {
    if (post.id == id) return post;
  }
  return null;
}

class ExploreEmpty extends StatelessWidget {
  const ExploreEmpty({required this.label, required this.onCreate, super.key});

  final String label;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public_rounded,
            size: 26,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onCreate,
            child: Text(context.l10n.ui('New Post')),
          ),
        ],
      ),
    );
  }
}

class ExploreFailure extends StatelessWidget {
  const ExploreFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.ui('Explore could not be loaded.')),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.ui('Try Again')),
          ),
        ],
      ),
    );
  }
}

class ExploreLoadingMore extends StatelessWidget {
  const ExploreLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
