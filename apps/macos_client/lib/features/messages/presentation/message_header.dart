import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';

class MessageHeader extends StatelessWidget {
  const MessageHeader({
    required this.conversation,
    required this.displayName,
    required this.onSearch,
    required this.onContactInfo,
    super.key,
  });

  final Conversation conversation;
  final String displayName;
  final VoidCallback onSearch;
  final VoidCallback onContactInfo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glassStrong,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Container(
        key: const Key('message-header'),
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
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
              key: const Key('message-search-open'),
              tooltip: 'Search messages',
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, size: 19),
            ),
            IconButton(
              key: const Key('message-contact-info-open'),
              tooltip: 'View contact info',
              onPressed: onContactInfo,
              icon: const Icon(Icons.person_outline_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}
