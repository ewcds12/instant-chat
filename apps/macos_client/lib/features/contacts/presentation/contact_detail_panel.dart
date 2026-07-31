import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_detail_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_links_dialog.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
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
          ? const _NoContactSelected()
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
        _ContactDetailHeader(
          disabled: widget.disabled,
          onRemove: widget.onRemove,
        ),
        Expanded(
          child: ContactDetailContent(
            contact: widget.contact,
            accessToken: widget.accessToken,
            disabled: widget.disabled,
            sharedContent: shared,
            onMessage: widget.onMessage,
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

class _ContactDetailHeader extends StatelessWidget {
  const _ContactDetailHeader({required this.disabled, required this.onRemove});

  final bool disabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassPanel(
      radius: 0,
      tint: RetroColors.glassStrong,
      borderColor: Colors.transparent,
      shadows: const [],
      child: Container(
        key: const Key('contact-detail-header'),
        height: RetroMetrics.contactDetailHeaderHeight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Contact Info',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuButton<_ContactMenuAction>(
              tooltip: 'Contact options',
              enabled: !disabled,
              onSelected: (action) {
                if (action == _ContactMenuAction.remove) {
                  onRemove();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ContactMenuAction.remove,
                  child: Text('Remove Contact…'),
                ),
              ],
              icon: const Icon(Icons.more_horiz_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoContactSelected extends StatelessWidget {
  const _NoContactSelected();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 32,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Select a contact',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a contact from the directory to view their details.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _ContactMenuAction { remove }
