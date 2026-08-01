import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class MessageReplyPreview extends StatelessWidget {
  const MessageReplyPreview({
    required this.reply,
    required this.isMine,
    super.key,
  });

  final MessageReply reply;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isMine ? colors.onPrimary : colors.onSurfaceVariant;
    return _ReplyPreviewBody(
      key: ValueKey('message-reply-preview-${reply.id}'),
      senderName: reply.sender.displayName,
      summary: messageReplySummary(
        kind: reply.kind,
        body: reply.body,
        filename: reply.filename,
        recalledAt: reply.recalledAt,
      ),
      titleColor: isMine ? foreground.withValues(alpha: 0.86) : colors.primary,
      bodyColor: foreground.withValues(alpha: isMine ? 0.74 : 1),
      accentColor: foreground.withValues(alpha: isMine ? 0.68 : 0.55),
    );
  }
}

class MessageReplyComposerPreview extends StatelessWidget {
  const MessageReplyComposerPreview({
    required this.message,
    required this.onCancel,
    super.key,
  });

  final Message message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('message-reply-draft'),
      padding: const EdgeInsets.fromLTRB(
        RetroMetrics.composerReplyHorizontalInset,
        RetroMetrics.composerReplyTopInset,
        RetroMetrics.composerReplyTrailingInset,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ComposerReplyCard(
              senderName: message.sender.displayName,
              summary: messageReplySummary(
                kind: message.kind,
                body: message.body,
                filename: message.file?.filename ?? '',
                recalledAt: message.recalledAt,
              ),
            ),
          ),
          const SizedBox(width: RetroMetrics.spaceSmall / 2),
          IconButton(
            key: const Key('message-reply-cancel'),
            tooltip: 'Cancel reply',
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ComposerReplyCard extends StatelessWidget {
  const _ComposerReplyCard({required this.senderName, required this.summary});

  final String senderName;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('message-reply-draft-card'),
      padding: const EdgeInsets.symmetric(
        horizontal: RetroMetrics.composerReplyCardHorizontalInset,
        vertical: RetroMetrics.composerReplyCardVerticalInset,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(
          RetroMetrics.composerReplyCardRadius,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const Key('message-reply-draft-accent'),
              width: RetroMetrics.composerReplyAccentWidth,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(RetroMetrics.cornerPill),
              ),
            ),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: RetroMetrics.composerReplyLineGap),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreviewBody extends StatelessWidget {
  const _ReplyPreviewBody({
    required this.senderName,
    required this.summary,
    required this.titleColor,
    required this.bodyColor,
    required this.accentColor,
    super.key,
  });

  final String senderName;
  final String summary;
  final Color titleColor;
  final Color bodyColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: RetroMetrics.messageReplyTextInset),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: RetroMetrics.messageReplyAccentWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: titleColor,
              fontSize: RetroMetrics.messageReplyTitleSize,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: RetroMetrics.messageReplyLineGap),
          Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: bodyColor,
              fontSize: RetroMetrics.messageReplyBodySize,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

String messageReplySummary({
  required MessageKind kind,
  required String body,
  required String filename,
  required DateTime? recalledAt,
}) {
  if (recalledAt != null) {
    return 'Message recalled';
  }
  return switch (kind) {
    MessageKind.text => body,
    MessageKind.image => 'Photo',
    MessageKind.file => filename.isEmpty ? 'File' : filename,
  };
}
