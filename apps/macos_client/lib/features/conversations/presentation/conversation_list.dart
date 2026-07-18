import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_list_row.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({
    required this.conversations,
    required this.accessToken,
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
  final String accessToken;
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
                      return ConversationListRow(
                        conversation: conversation,
                        accessToken: accessToken,
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
