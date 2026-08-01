import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_bubble.dart';
import 'package:instant_chat/features/messages/presentation/message_recall_stamp.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/messages/presentation/message_timestamp.dart';

part 'message_history_pagination.dart';

class MessageHistory extends StatelessWidget {
  const MessageHistory({
    required this.value,
    required this.scrollController,
    required this.accessToken,
    required this.currentUserId,
    this.targetMessageId,
    required this.onLoadOlder,
    required this.onOpenFile,
    required this.onOpenLink,
    required this.onDownloadImage,
    required this.onRecall,
    required this.onDelete,
    this.onReply,
    super.key,
  });

  final MessagesState value;
  final ScrollController scrollController;
  final String accessToken;
  final String currentUserId;
  final String? targetMessageId;
  final VoidCallback onLoadOlder;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(Uri link) onOpenLink;
  final Future<void> Function(MessageImage image) onDownloadImage;
  final Future<bool> Function(Message message) onRecall;
  final Future<bool> Function(Message message) onDelete;
  final ValueChanged<Message>? onReply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageMessages = _messageImages(value.messages);
    if (value.messages.isEmpty) {
      return Center(
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
      );
    }
    final now = DateTime.now();
    final targetIndex = targetMessageId == null
        ? -1
        : value.messages.indexWhere((message) => message.id == targetMessageId);
    final history = targetIndex < 0
        ? ListView.separated(
            key: const Key('message-history-list'),
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              RetroMetrics.messageHistoryHorizontalInset,
              32,
              RetroMetrics.messageHistoryHorizontalInset,
              28,
            ),
            itemCount: value.messages.length,
            separatorBuilder: (_, index) {
              final nextMessage = value.messages[index + 1];
              if (!shouldShowMessageTimestamp(
                previousTimestamp: value.messages[index].createdAt,
                timestamp: nextMessage.createdAt,
              )) {
                return const SizedBox(height: 13);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: MessageTimestamp(
                  timestamp: nextMessage.createdAt,
                  now: now,
                ),
              );
            },
            itemBuilder: (context, index) {
              final bubble = _messageBubble(
                context,
                value.messages[index],
                imageMessages,
              );
              if (index != 0) {
                return bubble;
              }
              return Column(
                children: [
                  MessageTimestamp(
                    timestamp: value.messages[index].createdAt,
                    now: now,
                  ),
                  const SizedBox(height: 16),
                  bubble,
                ],
              );
            },
          )
        : _TargetedMessageHistory(
            value: value,
            scrollController: scrollController,
            targetIndex: targetIndex,
            messageBuilder: (index) =>
                _messageBubble(context, value.messages[index], imageMessages),
            now: now,
          );
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_shouldLoadOlderMessages(
              notification,
              value: value,
              targetIndex: targetIndex,
            )) {
              onLoadOlder();
            }
            return false;
          },
          child: history,
        ),
        if (value.isLoadingOlder) const _MessageHistoryLoadingIndicator(),
      ],
    );
  }

  Widget _messageBubble(
    BuildContext context,
    Message message,
    List<MessageImage> imageMessages,
  ) {
    if (message.recalledAt != null) {
      return MessageRecallStamp(
        message: message,
        isMine: message.sender.id == currentUserId,
      );
    }
    return MessageBubble(
      message: message,
      isMine: message.sender.id == currentUserId,
      showSenderAvatar: true,
      imageMessages: imageMessages,
      accessToken: accessToken,
      onOpenFile: onOpenFile,
      onOpenLink: onOpenLink,
      onDownloadImage: onDownloadImage,
      onRecall: onRecall,
      onDelete: onDelete,
      onReply: onReply,
    );
  }
}

class _TargetedMessageHistory extends StatelessWidget {
  const _TargetedMessageHistory({
    required this.value,
    required this.scrollController,
    required this.targetIndex,
    required this.messageBuilder,
    required this.now,
  });

  final MessagesState value;
  final ScrollController scrollController;
  final int targetIndex;
  final Widget Function(int index) messageBuilder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final target = value.messages[targetIndex];
    final centerKey = ValueKey('message-history-center-${target.id}');
    return CustomScrollView(
      key: const Key('message-history-list'),
      controller: scrollController,
      center: centerKey,
      anchor: 0.34,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            RetroMetrics.messageHistoryHorizontalInset,
            32,
            RetroMetrics.messageHistoryHorizontalInset,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _entry(context, index),
              childCount: targetIndex,
            ),
          ),
        ),
        SliverPadding(
          key: centerKey,
          padding: const EdgeInsets.symmetric(
            horizontal: RetroMetrics.messageHistoryHorizontalInset,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _separator(targetIndex, target),
                Container(
                  key: ValueKey('message-history-target-${target.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: RetroColors.primarySoft,
                    borderRadius: BorderRadius.circular(RetroMetrics.corner),
                  ),
                  child: messageBuilder(targetIndex),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            RetroMetrics.messageHistoryHorizontalInset,
            0,
            RetroMetrics.messageHistoryHorizontalInset,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _entry(context, targetIndex + index + 1),
              childCount: value.messages.length - targetIndex - 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _entry(BuildContext context, int index, {bool includeGap = true}) {
    final message = value.messages[index];
    final separator = _separator(index, message);
    return Column(children: [if (includeGap) separator, messageBuilder(index)]);
  }

  Widget _separator(int index, Message message) {
    if (index == 0) {
      return Column(
        children: [
          MessageTimestamp(timestamp: message.createdAt, now: now),
          const SizedBox(height: 16),
        ],
      );
    }
    if (!shouldShowMessageTimestamp(
      previousTimestamp: value.messages[index - 1].createdAt,
      timestamp: message.createdAt,
    )) {
      return const SizedBox(height: 13);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: MessageTimestamp(timestamp: message.createdAt, now: now),
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
