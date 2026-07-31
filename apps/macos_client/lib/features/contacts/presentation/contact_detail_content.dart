import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_content.dart';
import 'package:instant_chat/features/contacts/presentation/contact_shared_section.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class ContactDetailContent extends StatelessWidget {
  const ContactDetailContent({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.sharedContent,
    required this.onMessage,
    required this.onRetryShared,
    required this.onOpenImage,
    required this.onOpenFile,
    required this.onOpenLinks,
    super.key,
  });

  final Contact contact;
  final String accessToken;
  final bool disabled;
  final AsyncValue<ContactSharedContent> sharedContent;
  final VoidCallback onMessage;
  final VoidCallback onRetryShared;
  final ValueChanged<MessageImage> onOpenImage;
  final ValueChanged<MessageFile> onOpenFile;
  final ValueChanged<List<Uri>> onOpenLinks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: RetroMetrics.contactDetailContentMaxWidth,
        ),
        child: SingleChildScrollView(
          key: const Key('contact-detail-scroll-view'),
          padding: const EdgeInsets.fromLTRB(
            RetroMetrics.contactDetailContentHorizontalInset,
            RetroMetrics.contactDetailContentVerticalInset,
            RetroMetrics.contactDetailContentHorizontalInset,
            RetroMetrics.spaceLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityRow(
                contact: contact,
                accessToken: accessToken,
                disabled: disabled,
                onMessage: onMessage,
              ),
              const Divider(),
              const SizedBox(height: RetroMetrics.spaceMedium),
              ContactSharedSection(
                value: sharedContent,
                onRetry: onRetryShared,
                onSeeAll: onMessage,
                onOpenImage: onOpenImage,
                onOpenFile: onOpenFile,
                onOpenLinks: onOpenLinks,
                accessToken: accessToken,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.onMessage,
  });

  final Contact contact;
  final String accessToken;
  final bool disabled;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final user = contact.user;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      key: const Key('contact-detail-identity'),
      height: RetroMetrics.contactDetailHeroHeight,
      child: Row(
        children: [
          ProfileAvatar(
            name: user.displayName,
            accessToken: accessToken,
            avatarUrl: user.avatarUrl,
            radius: RetroMetrics.contactDetailHeroAvatarRadius,
          ),
          const SizedBox(width: RetroMetrics.spaceMedium),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: RetroMetrics.contactDetailMessageHeight,
            child: FilledButton.icon(
              key: const Key('contact-detail-message'),
              onPressed: disabled ? null : onMessage,
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  0,
                  RetroMetrics.contactDetailMessageHeight,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Message'),
            ),
          ),
        ],
      ),
    );
  }
}
