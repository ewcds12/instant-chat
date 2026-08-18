import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_body.dart';

class PostCommentRow extends StatefulWidget {
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
  State<PostCommentRow> createState() => _PostCommentRowState();
}

class _PostCommentRowState extends State<PostCommentRow> {
  static const _replyBatchSize = 5;

  var _visibleReplyCount = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: ValueKey('post-comment-${widget.comment.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostCommentBody(
          comment: widget.comment,
          accessToken: widget.accessToken,
          isOwnComment: widget.comment.author.id == widget.currentUserId,
          onReply: widget.onReply,
          onDelete: widget.onDelete,
        ),
        if (widget.replies.isNotEmpty) _replySection(colors),
        Divider(
          key: ValueKey('post-comment-divider-${widget.comment.id}'),
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

  Widget _replySection(ColorScheme colors) {
    final visibleReplies = widget.replies
        .take(_visibleReplyCount)
        .toList(growable: false);
    final remaining = widget.replies.length - visibleReplies.length;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < visibleReplies.length; index++) ...[
              PostCommentBody(
                comment: visibleReplies[index],
                accessToken: widget.accessToken,
                isOwnComment:
                    visibleReplies[index].author.id == widget.currentUserId,
                compact: true,
                onReply: widget.onReply,
                onDelete: widget.onDelete,
              ),
              if (index < visibleReplies.length - 1)
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RetroMetrics.postReplyHorizontalInset,
                2,
                RetroMetrics.postReplyHorizontalInset,
                6,
              ),
              child: Wrap(
                spacing: RetroMetrics.spaceMedium,
                children: [
                  if (_visibleReplyCount == 0)
                    _replyControl(
                      key: ValueKey(
                        'post-comment-show-replies-${widget.comment.id}',
                      ),
                      label: _collapsedLabel,
                      onPressed: _showMoreReplies,
                    )
                  else ...[
                    if (remaining > 0)
                      _replyControl(
                        key: ValueKey(
                          'post-comment-show-more-replies-${widget.comment.id}',
                        ),
                        label:
                            'Show ${remaining.clamp(1, _replyBatchSize)} more',
                        onPressed: _showMoreReplies,
                      ),
                    _replyControl(
                      key: ValueKey(
                        'post-comment-collapse-replies-${widget.comment.id}',
                      ),
                      label: 'Collapse',
                      onPressed: _collapseReplies,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _collapsedLabel {
    final count = widget.replies.length;
    return 'Show $count ${count == 1 ? 'reply' : 'replies'}';
  }

  Widget _replyControl({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  void _showMoreReplies() {
    setState(() {
      _visibleReplyCount = (_visibleReplyCount + _replyBatchSize).clamp(
        0,
        widget.replies.length,
      );
    });
  }

  void _collapseReplies() {
    setState(() => _visibleReplyCount = 0);
  }
}
