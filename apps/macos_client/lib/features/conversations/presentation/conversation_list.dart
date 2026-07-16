import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({
    required this.conversations,
    required this.selectedId,
    required this.query,
    required this.isRefreshing,
    required this.errorMessage,
    required this.onQueryChanged,
    required this.onCompose,
    required this.onSelect,
    super.key,
  });

  final List<Conversation> conversations;
  final String? selectedId;
  final String query;
  final bool isRefreshing;
  final String? errorMessage;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onCompose;
  final ValueChanged<Conversation> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = conversations.where((conversation) {
      if (normalizedQuery.isEmpty) {
        return true;
      }
      return conversation.peer.displayName.toLowerCase().contains(
            normalizedQuery,
          ) ||
          conversation.peer.username.toLowerCase().contains(normalizedQuery);
    }).toList();

    return GlassPanel(
      radius: 0,
      tint: RetroColors.glass,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      key: const Key('conversation-search'),
                      onChanged: onQueryChanged,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        fillColor: RetroColors.glassStrong,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'New conversation',
                  onPressed: onCompose,
                  icon: const Icon(Icons.edit_square, size: 18),
                ),
              ],
            ),
          ),
          if (isRefreshing) const LinearProgressIndicator(minHeight: 1),
          if (errorMessage case final message?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
                      child: Text(
                        conversations.isEmpty
                            ? 'No conversations yet'
                            : 'No matching conversations',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) {
                      final isNextToSelected =
                          filtered[index].id == selectedId ||
                          filtered[index + 1].id == selectedId;

                      if (isNextToSelected) {
                        return const SizedBox(height: 8);
                      }

                      return Divider(
                        height: 8,
                        indent: 64,
                        endIndent: 14,
                        color: colors.outlineVariant,
                      );
                    },
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];
                      return _ConversationRow(
                        conversation: conversation,
                        selected: conversation.id == selectedId,
                        onOpen: () => onSelect(conversation),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conversation,
    required this.selected,
    required this.onOpen,
  });

  final Conversation conversation;
  final bool selected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
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
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selected
                      ? colors.primary
                      : colors.surfaceContainerHigh,
                  foregroundColor: selected
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                  child: Text(_initials(conversation.peer.displayName)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
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
                        'Direct message with @${conversation.peer.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    _shortDate(conversation.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
