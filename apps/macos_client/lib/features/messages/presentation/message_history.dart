import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';

class MessageHistory extends StatelessWidget {
  const MessageHistory({
    required this.value,
    required this.scrollController,
    required this.accessToken,
    required this.currentUserId,
    required this.onLoadOlder,
    required this.onOpenFile,
    required this.onDownloadImage,
    super.key,
  });

  final MessagesState value;
  final ScrollController scrollController;
  final String accessToken;
  final String currentUserId;
  final VoidCallback onLoadOlder;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(MessageImage image) onDownloadImage;

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
              padding: const EdgeInsets.fromLTRB(
                RetroMetrics.messageHistoryHorizontalInset,
                32,
                RetroMetrics.messageHistoryHorizontalInset,
                28,
              ),
              itemCount: value.messages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 13),
              itemBuilder: (context, index) {
                final message = value.messages[index];
                return MessageBubble(
                  message: message,
                  isMine: message.sender.id == currentUserId,
                  showSenderAvatar: true,
                  imageMessages: imageMessages,
                  accessToken: accessToken,
                  onOpenFile: onOpenFile,
                  onDownloadImage: onDownloadImage,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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
