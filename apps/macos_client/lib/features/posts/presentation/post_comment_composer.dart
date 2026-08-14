import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class PostCommentComposer extends StatefulWidget {
  const PostCommentComposer({
    required this.user,
    required this.accessToken,
    required this.disabled,
    required this.onSend,
    required this.focusNode,
    this.errorMessage,
    super.key,
  });

  final AuthUser user;
  final String accessToken;
  final bool disabled;
  final Future<bool> Function(String body) onSend;
  final FocusNode focusNode;
  final String? errorMessage;

  @override
  State<PostCommentComposer> createState() => _PostCommentComposerState();
}

class _PostCommentComposerState extends State<PostCommentComposer> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canSend = !widget.disabled && _controller.text.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(RetroMetrics.postCommentComposerInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.errorMessage case final message?) ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
              const SizedBox(height: 7),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ProfileAvatar(
                  name: widget.user.displayName,
                  accessToken: widget.accessToken,
                  avatarUrl: widget.user.avatarUrl,
                  radius: RetroMetrics.postCommentAvatarRadius,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const _NoScrollbarBehavior(),
                    child: TextField(
                      key: const Key('post-comment-field'),
                      controller: _controller,
                      focusNode: widget.focusNode,
                      enabled: !widget.disabled,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 500,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Write a comment',
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: colors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            RetroMetrics.postCommentComposerCorner,
                          ),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            RetroMetrics.postCommentComposerCorner,
                          ),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: RetroMetrics.postCommentSendDiameter,
                  child: IconButton.filled(
                    key: const Key('post-comment-send'),
                    tooltip: 'Post comment',
                    padding: EdgeInsets.zero,
                    onPressed: canSend ? _send : null,
                    icon: widget.disabled
                        ? const SizedBox.square(
                            dimension: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Icon(Icons.arrow_upward_rounded, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || widget.disabled) return;
    if (await widget.onSend(body) && mounted) {
      _controller.clear();
      widget.focusNode.requestFocus();
    }
  }

  void _refresh() => setState(() {});
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
