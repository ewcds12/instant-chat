import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class ConversationListRow extends StatelessWidget {
  const ConversationListRow({
    required this.conversation,
    required this.selected,
    required this.accessToken,
    required this.onOpen,
    super.key,
  });

  final Conversation conversation;
  final bool selected;
  final String accessToken;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: _decoration(colors),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            child: _rowContent(context, colors),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(ColorScheme colors) {
    return BoxDecoration(
      color: selected ? RetroColors.primaryLight : Colors.transparent,
      border: selected
          ? Border.all(color: colors.primary.withValues(alpha: 0.24))
          : null,
      borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
      boxShadow: selected
          ? [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    );
  }

  Widget _rowContent(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        _avatar(colors),
        const SizedBox(width: 10),
        Expanded(child: _details(context, colors)),
        const SizedBox(width: 8),
        _metadata(context, colors),
      ],
    );
  }

  Widget _avatar(ColorScheme colors) => conversation.peer.avatarUrl == null
      ? CircleAvatar(
          radius: 20,
          backgroundColor: selected
              ? colors.primary
              : colors.surfaceContainerHigh,
          foregroundColor: selected
              ? colors.onPrimary
              : colors.onSurfaceVariant,
          child: Text(_initials(conversation.peer.displayName)),
        )
      : ProfileAvatar(
          name: conversation.peer.displayName,
          accessToken: accessToken,
          avatarUrl: conversation.peer.avatarUrl,
          radius: 20,
        );

  Widget _details(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conversation.peer.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          _lastMessagePreview(conversation.lastMessage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _metadata(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _shortDate(conversation.updatedAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        if (conversation.unreadCount > 0) ...[
          const SizedBox(height: 7),
          _UnreadBadge(count: conversation.unreadCount),
        ],
      ],
    );
  }
}

String _lastMessagePreview(ConversationLastMessage? message) {
  if (message == null) {
    return 'No messages yet';
  }
  return switch (message.kind) {
    'image' => '[Photo]',
    'file' => '[File]',
    _ => message.body.replaceAll(RegExp(r'\s+'), ' ').trim(),
  };
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initials(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0])
      .join()
      .toUpperCase();
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  return '${local.month}/${local.day}';
}
