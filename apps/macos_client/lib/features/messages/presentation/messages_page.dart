import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/message_search.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({required this.conversation, super.key});

  final Conversation conversation;

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = messagesControllerProvider(widget.conversation.id);
    final state = ref.watch(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          conversation: widget.conversation,
          onSearch: () =>
              showMessageSearch(context, state.value?.messages ?? const []),
          onRefresh: () => ref.invalidate(provider),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _LoadFailure(onRetry: () => ref.invalidate(provider)),
            data: (value) => MessageHistory(
              value: value,
              currentUserId: ref
                  .read(authControllerProvider)
                  .requireValue
                  .session!
                  .user
                  .id,
              onLoadOlder: () => ref.read(provider.notifier).loadOlder(),
            ),
          ),
        ),
        if (state.value case final value?) ...[
          if (value.errorMessage case final message?)
            _ErrorBar(message: message),
          if (value.failedMessage != null)
            _RetryBar(
              disabled: value.isSending,
              onRetry: () => ref.read(provider.notifier).retry(),
            ),
          MessageComposer(
            controller: _composer,
            disabled: value.isSending,
            recipientName: widget.conversation.peer.displayName,
            onSend: () => _send(provider),
          ),
        ],
      ],
    );
  }

  Future<void> _send(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    if (await ref.read(provider.notifier).send(_composer.text)) {
      _composer.clear();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.conversation,
    required this.onSearch,
    required this.onRefresh,
  });

  final Conversation conversation;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: Text(_initials(conversation.peer.displayName)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.peer.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${conversation.peer.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Search messages',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 18),
          ),
          PopupMenuButton<_HeaderAction>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
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
    );
  }
}

enum _HeaderAction { refresh }

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}

class _RetryBar extends StatelessWidget {
  const _RetryBar({required this.disabled, required this.onRetry});

  final bool disabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Expanded(child: Text('Message not sent')),
          TextButton(
            onPressed: disabled ? null : onRetry,
            child: const Text('Retry'),
          ),
        ],
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
