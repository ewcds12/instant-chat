import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class PostCommentRow extends StatelessWidget {
  const PostCommentRow({
    required this.comment,
    required this.replies,
    required this.accessToken,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    super.key,
  });

  final PostComment comment;
  final List<PostComment> replies;
  final String accessToken;
  final String currentUserId;
  final ValueChanged<PostComment> onReply;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: ValueKey('post-comment-${comment.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommentBody(
          comment: comment,
          accessToken: accessToken,
          isOwnComment: comment.author.id == currentUserId,
          onReply: onReply,
          onDelete: onDelete,
        ),
        if (replies.isNotEmpty) _replyList(colors),
        Divider(
          key: ValueKey('post-comment-divider-${comment.id}'),
          height: 1,
          thickness: 1,
          indent:
              RetroMetrics.explorePostHorizontalInset +
              RetroMetrics.postCommentAvatarRadius * 2 +
              10,
          endIndent: RetroMetrics.explorePostHorizontalInset,
          color: colors.outlineVariant,
        ),
      ],
    );
  }

  Widget _replyList(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(
        left: RetroMetrics.postReplyIndent,
        right: RetroMetrics.explorePostHorizontalInset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          children: [
            for (var index = 0; index < replies.length; index++) ...[
              _CommentBody(
                comment: replies[index],
                accessToken: accessToken,
                isOwnComment: replies[index].author.id == currentUserId,
                compact: true,
                onReply: onReply,
                onDelete: onDelete,
              ),
              if (index < replies.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent:
                      RetroMetrics.postReplyHorizontalInset +
                      RetroMetrics.postReplyAvatarRadius * 2 +
                      10,
                  color: colors.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentBody extends StatelessWidget {
  const _CommentBody({
    required this.comment,
    required this.accessToken,
    required this.isOwnComment,
    required this.onReply,
    required this.onDelete,
    this.compact = false,
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
          if (isOwnComment) _deleteMenu(colors),
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
                '@${comment.author.username} · ${postTime(comment.createdAt)}',
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
            child: Text('Reply', style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      ],
    );
  }

  Widget _deleteMenu(ColorScheme colors) {
    return PopupMenuButton<String>(
      tooltip: 'Comment actions',
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
                'Delete',
                style: TextStyle(fontSize: 13, color: colors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
