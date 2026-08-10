import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/expandable_post_text.dart';
import 'package:instant_chat/features/posts/presentation/post_image_grid.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

enum PostAction { delete, report, block }

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.accessToken,
    required this.isOwnPost,
    required this.onAction,
    required this.onDownloadImage,
    super.key,
  });

  final PublicPost post;
  final String accessToken;
  final bool isOwnPost;
  final ValueChanged<PostAction> onAction;
  final Future<void> Function(PublicPostImage image) onDownloadImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RetroMetrics.explorePostHorizontalInset,
        RetroMetrics.explorePostVerticalInset,
        RetroMetrics.explorePostHorizontalInset,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            name: post.author.displayName,
            accessToken: accessToken,
            avatarUrl: post.author.avatarUrl,
            radius: RetroMetrics.exploreAvatarRadius,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PostHeader(
                  post: post,
                  isOwnPost: isOwnPost,
                  onAction: onAction,
                ),
                if (post.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ExpandablePostText(text: post.body),
                ],
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PostImageGrid(
                    images: post.images,
                    accessToken: accessToken,
                    onDownloadImage: onDownloadImage,
                  ),
                ],
                const SizedBox(height: 8),
                const _PostActivityRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.isOwnPost,
    required this.onAction,
  });

  final PublicPost post;
  final bool isOwnPost;
  final ValueChanged<PostAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  post.author.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '@${post.author.username} · ${postTime(post.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        _PostMenu(isOwnPost: isOwnPost, onAction: onAction),
      ],
    );
  }
}

class _PostActivityRow extends StatefulWidget {
  const _PostActivityRow();

  @override
  State<_PostActivityRow> createState() => _PostActivityRowState();
}

class _PostActivityRowState extends State<_PostActivityRow> {
  var _liked = false;
  var _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      height: RetroMetrics.exploreActionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActivityIcon(icon: Icons.chat_bubble_outline_rounded, color: muted),
          _ActivityIcon(icon: Icons.repeat_rounded, color: muted),
          _ActivityIcon(
            icon: _liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _liked ? Theme.of(context).colorScheme.error : muted,
            onPressed: () => setState(() => _liked = !_liked),
            tooltip: _liked ? 'Unlike' : 'Like',
          ),
          _ActivityIcon(
            icon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _bookmarked ? Theme.of(context).colorScheme.primary : muted,
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
            tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({
    required this.icon,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Icon(icon, size: 17, color: color),
      );
    }
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      onPressed: onPressed,
      icon: Icon(icon, size: 17, color: color),
    );
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({required this.isOwnPost, required this.onAction});

  final bool isOwnPost;
  final ValueChanged<PostAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PostAction>(
      tooltip: 'Post actions',
      icon: const Icon(Icons.more_horiz_rounded, size: 18),
      splashRadius: 17,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: onAction,
      itemBuilder: (context) => isOwnPost
          ? [
              PopupMenuItem(
                value: PostAction.delete,
                height: 34,
                child: _MenuLabel(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Post',
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ]
          : const [
              PopupMenuItem(
                value: PostAction.report,
                height: 34,
                child: _MenuLabel(icon: Icons.flag_outlined, label: 'Report'),
              ),
              PopupMenuItem(
                value: PostAction.block,
                height: 34,
                child: _MenuLabel(
                  icon: Icons.block_rounded,
                  label: 'Block User',
                ),
              ),
            ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}

String postTime(DateTime value, [DateTime? reference]) {
  final local = value.toLocal();
  final now = reference ?? DateTime.now();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${local.month}/${local.day}/${local.year}';
}
