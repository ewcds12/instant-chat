import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_composer.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_row.dart';
import 'package:instant_chat/features/posts/presentation/post_comments_controller.dart';
import 'package:instant_chat/features/posts/presentation/post_detail_header.dart';

class PostDetailPanel extends ConsumerStatefulWidget {
  const PostDetailPanel({
    required this.post,
    required this.session,
    required this.onBack,
    required this.onPostAction,
    required this.onCommentCountChanged,
    required this.onLike,
    required this.onDownloadImage,
    super.key,
  });

  final PublicPost post;
  final AuthSession session;
  final VoidCallback onBack;
  final ValueChanged<PostAction> onPostAction;
  final ValueChanged<int> onCommentCountChanged;
  final VoidCallback onLike;
  final Future<void> Function(PublicPostImage image) onDownloadImage;

  @override
  ConsumerState<PostDetailPanel> createState() => _PostDetailPanelState();
}

class _PostDetailPanelState extends ConsumerState<PostDetailPanel> {
  final _scrollController = ScrollController();
  final _composerFocus = FocusNode();
  late int _commentCount;
  PostComment? _replyTarget;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
    _scrollController.addListener(_loadNearBottom);
  }

  @override
  void didUpdateWidget(covariant PostDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.commentCount != widget.post.commentCount) {
      _commentCount = widget.post.commentCount;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNearBottom)
      ..dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(postCommentsControllerProvider(widget.post.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostDetailHeader(onBack: widget.onBack),
        Expanded(child: _content(comments)),
        comments.when(
          loading: () => _composer(disabled: true),
          error: (_, _) => _composer(disabled: true),
          data: (state) => _composer(
            disabled: state.isSubmitting,
            errorMessage: state.errorMessage,
          ),
        ),
      ],
    );
  }

  Widget _content(AsyncValue<PostCommentsState> comments) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: comments.when(
        loading: () => _commentList(const [], loading: true),
        error: (_, _) => _commentList(const [], failed: true),
        data: (state) =>
            _commentList(state.comments, loadingMore: state.isLoadingMore),
      ),
    );
  }

  Widget _commentList(
    List<PostComment> comments, {
    bool loading = false,
    bool loadingMore = false,
    bool failed = false,
  }) {
    final roots = comments
        .where((comment) => comment.parentCommentId == null)
        .toList(growable: false);
    return ListView.separated(
      key: ValueKey('post-detail-${widget.post.id}'),
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount:
          2 + roots.length + ((loading || loadingMore || failed) ? 1 : 0),
      separatorBuilder: (_, index) => index == 0
          ? Divider(color: Theme.of(context).colorScheme.outlineVariant)
          : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RetroMetrics.exploreContentMaxWidth,
              ),
              child: PostCard(
                post: widget.post,
                accessToken: widget.session.accessToken,
                isOwnPost: widget.post.author.id == widget.session.user.id,
                onAction: widget.onPostAction,
                onComment: _focusComposer,
                onLike: widget.onLike,
                onDownloadImage: widget.onDownloadImage,
              ),
            ),
          );
        }
        if (index == 1) {
          return PostCommentsLabel(count: _commentCount);
        }
        final commentIndex = index - 2;
        if (commentIndex < roots.length) {
          final comment = roots[commentIndex];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RetroMetrics.exploreContentMaxWidth,
              ),
              child: PostCommentRow(
                key: ValueKey('post-comment-${comment.id}'),
                comment: comment,
                replies: comments
                    .where((reply) => reply.parentCommentId == comment.id)
                    .toList(growable: false),
                accessToken: widget.session.accessToken,
                currentUserId: widget.session.user.id,
                onReply: _reply,
                onDelete: _delete,
              ),
            ),
          );
        }
        if (failed) {
          return Center(
            child: TextButton(
              onPressed: () => ref.invalidate(
                postCommentsControllerProvider(widget.post.id),
              ),
              child: Text(context.l10n.ui('Try again')),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.all(14),
          child: Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _composer({required bool disabled, String? errorMessage}) {
    return PostCommentComposer(
      user: widget.session.user,
      accessToken: widget.session.accessToken,
      disabled: disabled,
      errorMessage: errorMessage,
      focusNode: _composerFocus,
      replyingTo: _replyTarget,
      onCancelReply: _cancelReply,
      onSend: _create,
    );
  }

  void _loadNearBottom() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 220) {
      ref
          .read(postCommentsControllerProvider(widget.post.id).notifier)
          .loadMore();
    }
  }

  Future<void> _delete(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.ui('Delete Comment?')),
        content: Text(
          context.l10n.ui('This comment will be permanently removed.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.ui('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.ui('Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final removed = await ref
          .read(postCommentsControllerProvider(widget.post.id).notifier)
          .delete(commentId);
      if (removed != null && mounted) {
        setState(() {
          _commentCount = (_commentCount - removed).clamp(0, 1 << 31);
          if (_replyTarget?.id == commentId ||
              _replyTarget?.parentCommentId == commentId) {
            _replyTarget = null;
          }
        });
        widget.onCommentCountChanged(-removed);
      }
    }
  }

  Future<bool> _create(String body, String? parentCommentId) async {
    final created = await ref
        .read(postCommentsControllerProvider(widget.post.id).notifier)
        .create(body, parentCommentId: parentCommentId);
    if (created && mounted) {
      setState(() {
        _commentCount++;
        _replyTarget = null;
      });
      widget.onCommentCountChanged(1);
    }
    return created;
  }

  void _focusComposer() {
    setState(() => _replyTarget = null);
    _composerFocus.requestFocus();
  }

  void _reply(PostComment comment) {
    setState(() => _replyTarget = comment);
    _composerFocus.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTarget = null);
}
