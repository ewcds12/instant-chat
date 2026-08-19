import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class PostActivityRow extends StatefulWidget {
  const PostActivityRow({
    required this.commentCount,
    required this.likeCount,
    required this.likedByMe,
    required this.onComment,
    required this.onLike,
    super.key,
  });

  final int commentCount;
  final int likeCount;
  final bool likedByMe;
  final VoidCallback onComment;
  final VoidCallback onLike;

  @override
  State<PostActivityRow> createState() => _PostActivityRowState();
}

class _PostActivityRowState extends State<PostActivityRow> {
  var _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      height: RetroMetrics.exploreActionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActivityIcon(
            icon: Icons.chat_bubble_outline_rounded,
            color: muted,
            label: widget.commentCount == 0 ? null : '${widget.commentCount}',
            onPressed: widget.onComment,
            tooltip: context.l10n.ui('Comments'),
          ),
          _ActivityIcon(
            icon: widget.likedByMe
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: widget.likedByMe
                ? Theme.of(context).colorScheme.error
                : muted,
            label: widget.likeCount == 0 ? null : '${widget.likeCount}',
            onPressed: widget.onLike,
            tooltip: context.l10n.ui(widget.likedByMe ? 'Unlike' : 'Like'),
          ),
          _ActivityIcon(
            icon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: _bookmarked ? Theme.of(context).colorScheme.primary : muted,
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
            tooltip: context.l10n.ui(
              _bookmarked ? 'Remove bookmark' : 'Bookmark',
            ),
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
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Icon(icon, size: 17, color: color),
      );
    }
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              if (label case final value?) ...[
                const SizedBox(width: 5),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
