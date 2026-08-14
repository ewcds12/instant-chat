import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class PostCommentRow extends StatelessWidget {
  const PostCommentRow({
    required this.comment,
    required this.accessToken,
    required this.isOwnComment,
    required this.onDelete,
    super.key,
  });

  final PostComment comment;
  final String accessToken;
  final bool isOwnComment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      key: ValueKey('post-comment-${comment.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.explorePostHorizontalInset,
        vertical: RetroMetrics.postCommentVerticalInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            name: comment.author.displayName,
            accessToken: accessToken,
            avatarUrl: comment.author.avatarUrl,
            radius: RetroMetrics.postCommentAvatarRadius,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '@${comment.author.username} · ${postTime(comment.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (isOwnComment)
            PopupMenuButton<String>(
              tooltip: 'Comment actions',
              icon: const Icon(Icons.more_horiz_rounded, size: 16),
              splashRadius: 15,
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              onSelected: (_) => onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  height: 32,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 15,
                        color: colors.error,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: 13, color: colors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
