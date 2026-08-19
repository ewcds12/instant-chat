import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/expandable_post_text.dart';
import 'package:instant_chat/features/posts/presentation/post_activity_row.dart';
import 'package:instant_chat/features/posts/presentation/post_image_grid.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

enum PostAction { delete, report }

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.accessToken,
    required this.isOwnPost,
    required this.onAction,
    required this.onComment,
    required this.onLike,
    required this.onDownloadImage,
    super.key,
  });

  final PublicPost post;
  final String accessToken;
  final bool isOwnPost;
  final ValueChanged<PostAction> onAction;
  final VoidCallback onComment;
  final VoidCallback onLike;
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
                PostActivityRow(
                  commentCount: post.commentCount,
                  likeCount: post.likeCount,
                  likedByMe: post.likedByMe,
                  onComment: onComment,
                  onLike: onLike,
                ),
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
                  '@${post.author.username} · '
                  '${postTime(post.createdAt, null, context.l10n)}',
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

class _PostMenu extends StatelessWidget {
  const _PostMenu({required this.isOwnPost, required this.onAction});

  final bool isOwnPost;
  final ValueChanged<PostAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PostAction>(
      tooltip: context.l10n.ui('Post actions'),
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
                  label: context.l10n.ui('Delete Post'),
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ]
          : [
              PopupMenuItem(
                value: PostAction.report,
                height: 34,
                child: _MenuLabel(
                  icon: Icons.flag_outlined,
                  label: context.l10n.ui('Report'),
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

String postTime(
  DateTime value, [
  DateTime? reference,
  AppLocalizations? localizations,
]) {
  final local = value.toLocal();
  final now = reference ?? DateTime.now();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return localizations?.ui('Now') ?? 'Now';
  if (difference.inHours < 1) {
    return localizations?.relativeMinutes(difference.inMinutes) ??
        '${difference.inMinutes}m';
  }
  if (difference.inDays < 1) {
    return localizations?.relativeHours(difference.inHours) ??
        '${difference.inHours}h';
  }
  if (difference.inDays < 7) {
    return localizations?.relativeDays(difference.inDays) ??
        '${difference.inDays}d';
  }
  return '${local.month}/${local.day}/${local.year}';
}
