import 'package:flutter/material.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';

class MessageHistory extends StatelessWidget {
  const MessageHistory({
    required this.value,
    required this.currentUserId,
    required this.onLoadOlder,
    super.key,
  });

  final MessagesState value;
  final String currentUserId;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (value.messages.isEmpty) {
      return ColoredBox(
        color: colors.surfaceContainerLowest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waving_hand_outlined, color: colors.outline, size: 30),
              const SizedBox(height: 12),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Send a message to start the conversation.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: Column(
        children: [
          if (value.nextCursor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: value.isLoadingOlder || value.isSending
                    ? null
                    : onLoadOlder,
                child: Text(
                  value.isLoadingOlder ? 'Loading…' : 'Load older messages',
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(30, 88, 30, 24),
              itemCount: value.messages.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DayDivider(date: value.messages.first.createdAt);
                }
                final message = value.messages[index - 1];
                return _MessageBubble(
                  message: message,
                  isMine: message.sender.id == currentUserId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMine ? colors.primary : colors.surfaceContainer;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            key: ValueKey('message-bubble-${message.id}'),
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 0),
                bottomRight: Radius.circular(isMine ? 0 : 18),
              ),
            ),
            child: SelectableText(
              message.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isMine ? colors.onPrimary : colors.onSurface,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _messageTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Divider(color: colors.outlineVariant)),
              const SizedBox(width: 14),
              Text(
                _dayLabel(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Divider(color: colors.outlineVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

String _messageTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _dayLabel(DateTime value) {
  final local = value.toLocal();
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  if (_sameDay(local, today)) {
    return 'Today';
  }
  if (_sameDay(local, yesterday)) {
    return 'Yesterday';
  }
  return '${local.month}/${local.day}/${local.year}';
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
