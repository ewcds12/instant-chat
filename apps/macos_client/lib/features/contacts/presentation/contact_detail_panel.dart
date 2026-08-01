import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
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

class ContactDetailPanel extends StatelessWidget {
  const ContactDetailPanel({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
    super.key,
  });

  final Contact? contact;
  final String accessToken;
  final bool disabled;
  final VoidCallback? onMessage;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LiquidGradientBackground(
      child: contact == null
          ? const ContactDetailEmptyState()
          : _ContactDetail(
              contact: contact!,
              accessToken: accessToken,
              disabled: disabled,
              onMessage: onMessage!,
              onRemove: onRemove!,
            ),
    );
  }
}

class _ContactDetail extends ConsumerStatefulWidget {
  const _ContactDetail({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
    required this.onRemove,
  });

  final Contact contact;
  final String accessToken;
  final bool disabled;
  final VoidCallback onMessage;
  final VoidCallback onRemove;

  @override
  ConsumerState<_ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends ConsumerState<_ContactDetail> {
  ContactSharedContentRequest get _request =>
      (contactUserId: widget.contact.user.id, accessToken: widget.accessToken);

  @override
  Widget build(BuildContext context) {
    final shared = ref.watch(contactSharedContentProvider(_request));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContactDetailHeader(
          disabled: widget.disabled,
          onSearch: _openHistorySearch,
          onRemove: widget.onRemove,
        ),
        Expanded(
          child: ContactDetailContent(
            contact: widget.contact,
            accessToken: widget.accessToken,
            disabled: widget.disabled,
            sharedContent: shared,
            onMessage: _openConversation,
            onOpenAvatar: widget.contact.user.avatarUrl == null
                ? null
                : _openAvatar,
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
    final contact = widget.contact;
    try {
      final authState = await ref.read(authControllerProvider.future);
      final session = authState.session;
      if (!mounted || session == null) {
        return;
      }
      final conversations = await ref.read(
        conversationsControllerProvider.future,
      );
      final conversation = _conversationForContact(
        conversations.conversations,
        contact.user.id,
      );
      if (!mounted) {
        return;
      }
      if (conversation == null) {
        _showMessage('This chat is not available yet.');
        return;
      }
      final message = await showContactMessageSearch(
        context: context,
        contact: contact,
        currentUserId: session.user.id,
        conversationId: conversation.id,
        accessToken: widget.accessToken,
        gateway: ref.read(messageGatewayProvider),
      );
      if (!mounted || message == null) {
        return;
      }
      ref
          .read(messageNavigationTargetProvider.notifier)
          .select(conversationId: conversation.id, messageId: message.id);
      widget.onMessage();
    } catch (_) {
      if (mounted) {
        _showMessage('Message history could not be opened.');
      }
    }
  }

  void _openAvatar() {
    final user = widget.contact.user;
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
        _showMessage('File could not be saved.');
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
        _showMessage('Image could not be saved.');
      }
    }
  }

  Future<void> _openLinks(List<Uri> links) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ContactSharedLinksDialog(
        links: links,
        onOpen: (link) async {
          try {
            await ref.read(localUrlLauncherProvider).open(link);
          } catch (_) {
            if (mounted) {
              _showMessage('Link could not be opened.');
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
