import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_list.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({required this.onCompose, super.key});

  final VoidCallback onCompose;

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  String? _selectedConversationId;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(conversationsControllerProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (value) {
        final selected = _findSelected(value.conversations);
        return Row(
          children: [
            SizedBox(
              key: const Key('conversation-column'),
              width: 300,
              child: ConversationList(
                conversations: value.conversations,
                selectedId: selected?.id,
                query: _query,
                isRefreshing: value.isSubmitting,
                errorMessage: value.errorMessage,
                onQueryChanged: (query) => setState(() => _query = query),
                onCompose: widget.onCompose,
                onSelect: (conversation) =>
                    setState(() => _selectedConversationId = conversation.id),
              ),
            ),
            VerticalDivider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: selected == null
                  ? const _NoConversationSelected()
                  : MessagesPage(conversation: selected),
            ),
          ],
        );
      },
    );
  }

  Conversation? _findSelected(List<Conversation> conversations) {
    for (final conversation in conversations) {
      if (conversation.id == _selectedConversationId) {
        return conversation;
      }
    }
    return null;
  }
}

class _NoConversationSelected extends StatelessWidget {
  const _NoConversationSelected();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 34,
              color: colors.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a conversation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a chat from the list to view its messages.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
