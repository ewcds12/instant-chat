import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(conversationsControllerProvider),
          child: const Text('RETRY CONVERSATIONS'),
        ),
      ),
      data: (value) => Padding(
        padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CONVERSATIONS // ${value.conversations.length}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh conversations',
                  onPressed: value.isSubmitting
                      ? null
                      : () => ref
                            .read(conversationsControllerProvider.notifier)
                            .refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: RetroMetrics.spaceSmall),
            const Text(
              'Direct conversation directory // real-time messaging is not active yet.',
            ),
            if (value.errorMessage case final message?) ...[
              const SizedBox(height: RetroMetrics.spaceSmall),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: RetroMetrics.spaceLarge),
            Expanded(
              child: value.conversations.isEmpty
                  ? const Center(
                      child: Text(
                        'NO CONVERSATIONS // OPEN A CONTACT TO BEGIN',
                      ),
                    )
                  : ListView.separated(
                      itemCount: value.conversations.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: RetroMetrics.spaceSmall),
                      itemBuilder: (context, index) => _ConversationRow(
                        conversation: value.conversations[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface,
          width: RetroMetrics.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined),
          const SizedBox(width: RetroMetrics.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.peer.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: RetroMetrics.spaceSmall),
                Text('@${conversation.peer.username} // NO MESSAGES YET'),
              ],
            ),
          ),
          Text('DIRECT', style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
