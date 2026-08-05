import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_file_card.dart';
import 'package:instant_chat/features/messages/presentation/message_context_menu.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_image_view.dart';
import 'package:instant_chat/features/messages/presentation/message_link_text.dart';
import 'package:instant_chat/features/messages/presentation/message_reply_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_translation_view.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSenderAvatar,
    required this.imageMessages,
    required this.accessToken,
    required this.onOpenFile,
    required this.onOpenLink,
    required this.onDownloadImage,
    required this.onRecall,
    required this.onDelete,
    this.onReply,
    this.onOpenReply,
    this.translation,
    this.onTranslate,
    this.onRemoveTranslation,
    this.onTranslationSettings,
    super.key,
  });

  final Message message;
  final bool isMine;
  final bool showSenderAvatar;
  final List<MessageImage> imageMessages;
  final String accessToken;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(Uri link) onOpenLink;
  final Future<void> Function(MessageImage image) onDownloadImage;
  final Future<bool> Function(Message message) onRecall;
  final Future<bool> Function(Message message) onDelete;
  final ValueChanged<Message>? onReply;
  final ValueChanged<String>? onOpenReply;
  final MessageTranslationPresentation? translation;
  final Future<void> Function(Message message)? onTranslate;
  final Future<void> Function(Message message)? onRemoveTranslation;
  final Future<void> Function()? onTranslationSettings;

  @override
  Widget build(BuildContext context) {
    final content = MessageContextMenu(
      message: message,
      isMine: isMine,
      onRecall: onRecall,
      onDelete: onDelete,
      onReply: onReply,
      onTranslate: onTranslate,
      onRemoveTranslation: onRemoveTranslation,
      onTranslationSettings: onTranslationSettings,
      translationVisible:
          translation?.status == MessageTranslationStatus.translated,
      child: _MessageContent(
        message: message,
        isMine: isMine,
        imageMessages: imageMessages,
        accessToken: accessToken,
        onOpenFile: onOpenFile,
        onOpenLink: onOpenLink,
        onDownloadImage: onDownloadImage,
        onOpenReply: onOpenReply,
        translation: translation,
      ),
    );
    final avatar = _MessageSenderAvatar(
      message: message,
      accessToken: accessToken,
    );
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSenderAvatar && !isMine) ...[
            avatar,
            const SizedBox(width: RetroMetrics.messageAvatarGap),
          ],
          content,
          if (showSenderAvatar && isMine) ...[
            const SizedBox(width: RetroMetrics.messageAvatarGap),
            avatar,
          ],
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
    required this.onOpenLink,
    required this.onDownloadImage,
    required this.onOpenReply,
    required this.translation,
  });

  final Message message;
  final bool isMine;
  final List<MessageImage> imageMessages;
  final String accessToken;
  final ValueChanged<MessageFile> onOpenFile;
  final Future<void> Function(Uri link) onOpenLink;
  final Future<void> Function(MessageImage image) onDownloadImage;
  final ValueChanged<String>? onOpenReply;
  final MessageTranslationPresentation? translation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = message.kind == MessageKind.image ? message.image : null;
    final file = message.kind == MessageKind.file ? message.file : null;
    final openReply = onOpenReply;
    final messageTextStyle =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: isMine ? colors.onPrimary : colors.onSurface,
          fontSize: 14,
          height: 1.28,
        );
    final translationWidth = translation == null
        ? null
        : _measureMessageTextWidth(context, messageTextStyle);
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
            constraints: const BoxConstraints(
              maxWidth: RetroMetrics.messageBubbleMaxWidth,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: RetroMetrics.messageBubbleHorizontalInset,
              vertical: RetroMetrics.messageBubbleVerticalInset,
            ),
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
              borderRadius: BorderRadius.circular(10),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.replyTo case final reply?) ...[
                  MessageReplyPreview(
                    reply: reply,
                    isMine: isMine,
                    onOpen: openReply == null
                        ? null
                        : () => openReply(reply.id),
                  ),
                  const SizedBox(height: RetroMetrics.messageReplyContentGap),
                ],
                MessageLinkText(
                  key: ValueKey('message-link-text-${message.id}'),
                  text: message.body,
                  style: messageTextStyle,
                  linkStyle: TextStyle(
                    color: isMine ? colors.onPrimary : colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: isMine ? colors.onPrimary : colors.primary,
                  ),
                  onOpenLink: onOpenLink,
                ),
                if (translation case final translation?) ...[
                  const SizedBox(height: RetroMetrics.spaceSmall),
                  SizedBox(
                    width: translationWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: (isMine ? colors.onPrimary : colors.onSurface)
                              .withValues(alpha: 0.18),
                        ),
                        MessageTranslationView(
                          messageId: message.id,
                          translation: translation,
                          isMine: isMine,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  double _measureMessageTextWidth(BuildContext context, TextStyle style) {
    final painter =
        TextPainter(
          text: TextSpan(text: message.body, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(
          maxWidth:
              RetroMetrics.messageBubbleMaxWidth -
              (RetroMetrics.messageBubbleHorizontalInset * 2),
        );
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _MessageSenderAvatar extends StatelessWidget {
  const _MessageSenderAvatar({
    required this.message,
    required this.accessToken,
  });

  final Message message;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: RetroMetrics.messageAvatarSlotWidth,
      child: Align(
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          key: Key('message-sender-avatar-frame-${message.id}'),
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
      ),
    );
  }
}
