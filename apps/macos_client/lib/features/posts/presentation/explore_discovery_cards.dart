import 'package:flutter/material.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class DiscoveryRailSection extends StatelessWidget {
  const DiscoveryRailSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.74),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          child,
        ],
      ),
    );
  }
}

class DiscoveryFeaturedPost extends StatelessWidget {
  const DiscoveryFeaturedPost({
    required this.post,
    required this.accessToken,
    required this.onTap,
    super.key,
  });

  final PublicPost post;
  final String accessToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = post.images.isEmpty ? null : post.images.first;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 88,
                height: 72,
                child: image == null
                    ? ColoredBox(
                        color: RetroColors.primaryLight,
                        child: Icon(
                          Icons.public_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Image.network(
                        _absoluteUrl(image.url),
                        fit: BoxFit.cover,
                        headers: bearerAuthorization(accessToken),
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: RetroColors.primaryLight,
                          child: Icon(Icons.broken_image_outlined, size: 20),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.author.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    post.body.isEmpty ? 'Shared a photo' : post.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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

class DiscoveryTopicRow extends StatelessWidget {
  const DiscoveryTopicRow({required this.post, required this.onTap, super.key});

  final PublicPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community · Recent',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              post.body.isEmpty
                  ? 'Photo from @${post.author.username}'
                  : post.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryPersonRow extends StatelessWidget {
  const DiscoveryPersonRow({
    required this.post,
    required this.accessToken,
    required this.onView,
    super.key,
  });

  final PublicPost post;
  final String accessToken;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          ProfileAvatar(
            name: post.author.displayName,
            accessToken: accessToken,
            avatarUrl: post.author.avatarUrl,
            radius: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '@${post.author.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(52, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onView,
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

class DiscoveryRailEmpty extends StatelessWidget {
  const DiscoveryRailEmpty({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _absoluteUrl(String path) {
  return Uri.parse(AppConfig.apiBaseUrl).resolve(path).toString();
}
