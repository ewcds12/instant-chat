import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class PostCommentBody extends StatelessWidget {
  const PostCommentBody({
    required this.comment,
    required this.accessToken,
    required this.isOwnComment,
    required this.onReply,
    required this.onDelete,
    this.compact = false,
    super.key,
  });

  final PostComment comment;
  final String accessToken;
  final bool isOwnComment;
  final bool compact;
  final ValueChanged<PostComment> onReply;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final horizontalInset = compact
        ? RetroMetrics.postReplyHorizontalInset
        : RetroMetrics.explorePostHorizontalInset;
    final verticalInset = compact
        ? RetroMetrics.postReplyVerticalInset
        : RetroMetrics.postCommentVerticalInset;
    return Padding(
      key: ValueKey('post-comment-body-${comment.id}'),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            name: comment.author.displayName,
            accessToken: accessToken,
            avatarUrl: comment.author.avatarUrl,
            radius: compact
                ? RetroMetrics.postReplyAvatarRadius
                : RetroMetrics.postCommentAvatarRadius,
          ),
          const SizedBox(width: 10),
          Expanded(child: _content(context, colors)),
          if (isOwnComment) _deleteMenu(context, colors),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme colors) {
    return Column(
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
                '@${comment.author.username} · '
                '${postTime(comment.createdAt, null, context.l10n)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(comment.body, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(
          height: RetroMetrics.postCommentActionHeight,
          child: TextButton(
            key: ValueKey('post-comment-reply-${comment.id}'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colors.onSurfaceVariant,
            ),
            onPressed: () => onReply(comment),
            child: Text(
              context.l10n.ui('Reply'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteMenu(BuildContext context, ColorScheme colors) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.ui('Comment actions'),
      icon: const Icon(Icons.more_horiz_rounded, size: 16),
      splashRadius: 15,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (_) => onDelete(comment.id),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 15, color: colors.error),
              const SizedBox(width: 7),
              Text(
                context.l10n.ui('Delete'),
                style: TextStyle(fontSize: 13, color: colors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
