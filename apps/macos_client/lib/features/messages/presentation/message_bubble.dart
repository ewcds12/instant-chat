import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_file_card.dart';
import 'package:instant_chat/features/messages/presentation/message_context_menu.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_image_view.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSenderAvatar,
    required this.imageMessages,
    required this.accessToken,
    required this.onOpenFile,
    required this.onDownloadImage,
    required this.onRecall,
    required this.onDelete,
    super.key,
  });

  final Message message;
  final bool isMine;
  final bool showSenderAvatar;
  final List<MessageImage> imageMessages;
  final String accessToken;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(MessageImage image) onDownloadImage;
  final Future<bool> Function(Message message) onRecall;
  final Future<bool> Function(Message message) onDelete;

  @override
  Widget build(BuildContext context) {
    final content = MessageContextMenu(
      message: message,
      isMine: isMine,
      onRecall: onRecall,
      onDelete: onDelete,
      child: _MessageContent(
        message: message,
        isMine: isMine,
        imageMessages: imageMessages,
        accessToken: accessToken,
        onOpenFile: onOpenFile,
        onDownloadImage: onDownloadImage,
      ),
    );
    final avatar = _MessageSenderAvatar(
      message: message,
      accessToken: accessToken,
      showAvatar: showSenderAvatar,
    );
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
            ? [
                content,
                const SizedBox(width: RetroMetrics.messageAvatarGap),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: RetroMetrics.messageAvatarGap),
                content,
              ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.isMine,
    required this.imageMessages,
    required this.accessToken,
    required this.onOpenFile,
    required this.onDownloadImage,
  });

  final Message message;
  final bool isMine;
  final List<MessageImage> imageMessages;
  final String accessToken;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(MessageImage image) onDownloadImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = message.kind == MessageKind.image ? message.image : null;
    final file = message.kind == MessageKind.file ? message.file : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (image != null)
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
              onDownload: onDownloadImage,
            ),
          )
        else if (file != null)
          MessageFileCard(
            key: ValueKey('message-file-${message.id}'),
            openKey: ValueKey('message-file-open-${message.id}'),
            file: file,
            isMine: isMine,
            onOpen: () => onOpenFile(file),
          )
        else
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
              border: isMine ? null : Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(RetroMetrics.cornerLarge),
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
            child: Text(
              message.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isMine ? colors.onPrimary : colors.onSurface,
                fontSize: 14,
                height: 1.28,
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageSenderAvatar extends StatelessWidget {
  const _MessageSenderAvatar({
    required this.message,
    required this.accessToken,
    required this.showAvatar,
  });

  final Message message;
  final String accessToken;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: RetroMetrics.messageAvatarSlotWidth,
      child: showAvatar
          ? Align(
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ProfileAvatar(
                    key: Key('message-sender-avatar-${message.id}'),
                    name: message.sender.displayName,
                    avatarUrl: message.sender.avatarUrl,
                    accessToken: accessToken,
                    radius: (RetroMetrics.messageAvatarDiameter - 4) / 2,
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
