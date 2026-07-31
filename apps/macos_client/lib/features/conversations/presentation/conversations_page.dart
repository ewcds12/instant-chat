import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_list.dart';
import 'package:instant_chat/features/conversations/presentation/conversation_selection.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_page.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({required this.onCompose, super.key});

  final VoidCallback onCompose;

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationsControllerProvider);
    final accessToken = ref
        .read(authControllerProvider)
        .requireValue
        .session!
        .accessToken;
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(conversationsControllerProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (value) {
        final selectedConversationId = ref.watch(
          selectedConversationIdProvider,
        );
        final selected = _findSelected(
          value.conversations,
          selectedConversationId,
        );
        return Row(
          children: [
            SizedBox(
              key: const Key('conversation-column'),
              width: RetroMetrics.conversationColumnWidth,
              child: ConversationList(
                conversations: value.conversations,
                accessToken: accessToken,
                selectedId: selected?.id,
                query: _query,
                isRefreshing: value.isSubmitting,
                errorMessage: value.errorMessage,
                onQueryChanged: (query) => setState(() => _query = query),
                onCompose: widget.onCompose,
                onSelect: (conversation) => ref
                    .read(selectedConversationIdProvider.notifier)
                    .select(conversation.id),
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

  Conversation? _findSelected(
    List<Conversation> conversations,
    String? selectedConversationId,
  ) {
    for (final conversation in conversations) {
      if (conversation.id == selectedConversationId) {
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
    return LiquidGradientBackground(
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
