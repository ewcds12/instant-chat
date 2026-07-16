import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_image_view.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';

class MessageHistory extends StatelessWidget {
  const MessageHistory({
    required this.value,
    required this.scrollController,
    required this.accessToken,
    required this.currentUserId,
    required this.onLoadOlder,
    super.key,
  });

  final MessagesState value;
  final ScrollController scrollController;
  final String accessToken;
  final String currentUserId;
  final VoidCallback onLoadOlder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageMessages = _messageImages(value.messages);
    if (value.messages.isEmpty) {
      return LiquidGradientBackground(
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
    return LiquidGradientBackground(
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
              key: const Key('message-history-list'),
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(34, 96, 34, 28),
              itemCount: value.messages.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 13),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DayDivider(date: value.messages.first.createdAt);
                }
                final message = value.messages[index - 1];
                return _MessageBubble(
                  message: message,
                  isMine: message.sender.id == currentUserId,
                  imageMessages: imageMessages,
                  accessToken: accessToken,
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
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.imageMessages,
    required this.accessToken,
  });

  final Message message;
  final bool isMine;
  final List<MessageImage> imageMessages;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = message.kind == MessageKind.image ? message.image : null;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (image == null)
            Container(
              key: ValueKey('message-bubble-${message.id}'),
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isMine ? null : RetroColors.glassStrong,
                gradient: isMine
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3C7BF0), RetroColors.primary],
                      )
                    : null,
                border: isMine
                    ? null
                    : Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? colors.primary.withValues(alpha: 0.2)
                        : const Color(0x120F172A),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SelectableText(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMine ? colors.onPrimary : colors.onSurface,
                  fontSize: 14,
                  height: 1.28,
                ),
              ),
            )
          else
            MessageImageView(
              key: ValueKey('message-image-${message.id}'),
              openKey: ValueKey('message-image-open-${message.id}'),
              image: image,
              accessToken: accessToken,
              onOpen: () => showMessageImagePreview(
                context: context,
                images: imageMessages,
                initialImage: image,
                accessToken: accessToken,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _messageTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 12,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Divider(color: colors.outlineVariant)),
          const SizedBox(width: 12),
          GlassPanel(
            radius: RetroMetrics.cornerPill,
            tint: RetroColors.glass,
            shadows: const [],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              _dayLabel(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: colors.outlineVariant)),
        ],
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

List<MessageImage> _messageImages(List<Message> messages) {
  final images = <MessageImage>[];
  for (final message in messages) {
    final image = message.image;
    if (message.kind == MessageKind.image && image != null) {
      images.add(image);
    }
  }
  return images;
}
