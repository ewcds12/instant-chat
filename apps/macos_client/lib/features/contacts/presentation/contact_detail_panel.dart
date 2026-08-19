import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_header.dart';
import 'package:instant_chat/features/contacts/presentation/contact_message_search.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_links_dialog.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_navigation_target.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class ContactDetailPanel extends StatelessWidget {
  const ContactDetailPanel({
    required this.user,
    this.remark = '',
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
    this.onSetRemark,
    this.conversationId,
    this.onBack,
    super.key,
  });

  final PublicUser? user;
  final String remark;
  final String accessToken;
  final bool disabled;
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;
  final VoidCallback? onSetRemark;
  final String? conversationId;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return LiquidGradientBackground(
      child: user == null
          ? const ContactDetailEmptyState()
          : _ContactDetail(
              user: user!,
              remark: remark,
              accessToken: accessToken,
              disabled: disabled,
              onMessage: onMessage!,
              onRemove: onRemove!,
              onSetRemark: onSetRemark ?? () {},
              conversationId: conversationId,
              onBack: onBack,
            ),
    );
  }
}

class _ContactDetail extends ConsumerStatefulWidget {
  const _ContactDetail({
    required this.user,
    required this.remark,
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
    required this.onSetRemark,
    required this.conversationId,
    required this.onBack,
  });

  final PublicUser user;
  final String remark;
  final String accessToken;
  final bool disabled;
  final VoidCallback onMessage;
  final VoidCallback onRemove;
  final VoidCallback onSetRemark;
  final String? conversationId;
  final VoidCallback? onBack;

  @override
  ConsumerState<_ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends ConsumerState<_ContactDetail> {
  ContactSharedContentRequest get _request =>
      (contactUserId: widget.user.id, accessToken: widget.accessToken);

  @override
  Widget build(BuildContext context) {
    final shared = ref.watch(contactSharedContentProvider(_request));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContactDetailHeader(
          disabled: widget.disabled,
          onSearch: _openHistorySearch,
          onSetRemark: widget.onSetRemark,
          onRemove: widget.onRemove,
          onBack: widget.onBack,
        ),
        Expanded(
          child: ContactDetailContent(
            user: widget.user,
            remark: widget.remark,
            accessToken: widget.accessToken,
            disabled: widget.disabled,
            sharedContent: shared,
            onMessage: _openConversation,
            onOpenAvatar: widget.user.avatarUrl == null ? null : _openAvatar,
            onRetryShared: () =>
                ref.invalidate(contactSharedContentProvider(_request)),
            onOpenImage: (image) => _openImage(shared.value?.images, image),
            onOpenFile: _openFile,
            onOpenLinks: _openLinks,
          ),
        ),
      ],
    );
  }

  void _openImage(List<MessageImage>? images, MessageImage initialImage) {
    final availableImages = images ?? [initialImage];
    showMessageImagePreview(
      context: context,
      images: availableImages,
      initialImage: initialImage,
      accessToken: widget.accessToken,
      onDownload: _downloadImage,
    );
  }

  void _openConversation() {
    ref.read(messageNavigationTargetProvider.notifier).clear();
    widget.onMessage();
  }

  Future<void> _openHistorySearch() async {
    try {
      final authState = await ref.read(authControllerProvider.future);
      final session = authState.session;
      if (!mounted || session == null) {
        return;
      }
      var conversationId = widget.conversationId;
      if (conversationId == null) {
        final conversations = await ref.read(
          conversationsControllerProvider.future,
        );
        conversationId = _conversationForContact(
          conversations.conversations,
          widget.user.id,
        )?.id;
      }
      if (!mounted) {
        return;
      }
      if (conversationId == null) {
        _showMessage(context.l10n.ui('This chat is not available yet.'));
        return;
      }
      final message = await showMessageHistorySearch(
        context: context,
        participantName: widget.user.displayName,
        currentUserId: session.user.id,
        conversationId: conversationId,
        accessToken: widget.accessToken,
        gateway: ref.read(messageGatewayProvider),
      );
      if (!mounted || message == null) {
        return;
      }
      ref
          .read(messageNavigationTargetProvider.notifier)
          .select(conversationId: conversationId, messageId: message.id);
      widget.onMessage();
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.ui('Message history could not be opened.'));
      }
    }
  }

  void _openAvatar() {
    final user = widget.user;
    final avatar = MessageImage(
      id: 'contact-avatar-${user.id}',
      url: user.avatarUrl!,
      contentType: 'image/png',
      byteSize: 0,
    );
    showMessageImagePreview(
      context: context,
      images: [avatar],
      initialImage: avatar,
      accessToken: widget.accessToken,
      onDownload: _downloadImage,
    );
  }

  Future<void> _openFile(MessageFile file) async {
    final actions = ref.read(localFileActionsProvider);
    final action = await actions.chooseAction(file.filename);
    if (!mounted || action == null) {
      return;
    }
    try {
      final path = await actions.chooseDownloadPath(file.filename);
      if (!mounted || path == null) {
        return;
      }
      await ref
          .read(messageGatewayProvider)
          .downloadFile(
            accessToken: widget.accessToken,
            file: file,
            destinationPath: path,
          );
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.ui('File could not be saved.'));
      }
    }
  }

  Future<void> _downloadImage(MessageImage image) async {
    final actions = ref.read(localFileActionsProvider);
    try {
      final path = await actions.chooseDownloadPath(
        messageImageDownloadFilename(image),
      );
      if (!mounted || path == null) {
        return;
      }
      final bytes = await ref
          .read(messageGatewayProvider)
          .downloadImage(accessToken: widget.accessToken, image: image);
      await actions.writeDownloadFile(path, bytes);
    } catch (_) {
      if (mounted) {
        _showMessage(context.l10n.ui('Image could not be saved.'));
      }
    }
  }

  Future<void> _openLinks(List<Uri> links) async {
    final localizations = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => ContactSharedLinksDialog(
        links: links,
        onOpen: (link) async {
          try {
            await ref.read(localUrlLauncherProvider).open(link);
          } catch (_) {
            if (mounted) {
              _showMessage(localizations.ui('Link could not be opened.'));
            }
          }
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Conversation? _conversationForContact(
  List<Conversation> conversations,
  String contactUserId,
) {
  for (final conversation in conversations) {
    if (conversation.kind == 'direct' &&
        conversation.peer.id == contactUserId) {
      return conversation;
    }
  }
  return null;
}
