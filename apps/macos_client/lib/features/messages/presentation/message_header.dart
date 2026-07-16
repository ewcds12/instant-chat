import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';

class MessageHeader extends StatelessWidget {
  const MessageHeader({
    required this.conversation,
    required this.onSearch,
    required this.onRefresh,
    super.key,
  });

  final Conversation conversation;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glassStrong,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: RetroColors.primaryLight,
              foregroundColor: colors.primary,
              child: Text(_initials(conversation.peer.displayName)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.peer.displayName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${conversation.peer.username}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Search messages',
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, size: 19),
            ),
            PopupMenuButton<_HeaderAction>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_horiz_rounded, size: 19),
              onSelected: (action) {
                if (action == _HeaderAction.refresh) {
                  onRefresh();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _HeaderAction.refresh,
                  child: Text('Refresh messages'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _HeaderAction { refresh }

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
