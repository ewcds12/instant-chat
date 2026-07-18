import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class MessageHeader extends StatelessWidget {
  const MessageHeader({
    required this.conversation,
    required this.accessToken,
    required this.onSearch,
    required this.onRefresh,
    super.key,
  });

  final Conversation conversation;
  final String accessToken;
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
            ProfileAvatar(
              name: conversation.peer.displayName,
              accessToken: accessToken,
              avatarUrl: conversation.peer.avatarUrl,
              radius: 19,
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
