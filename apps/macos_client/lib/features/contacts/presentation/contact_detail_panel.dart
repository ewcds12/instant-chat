import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/glass.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

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

class _ContactDetail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContactDetailHeader(
          contact: contact,
          accessToken: accessToken,
          disabled: disabled,
          onRemove: onRemove,
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.12),
            child: _ContactSummary(
              contact: contact,
              accessToken: accessToken,
              disabled: disabled,
              onMessage: onMessage,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactDetailHeader extends StatelessWidget {
  const _ContactDetailHeader({
    required this.contact,
    required this.accessToken,
    required this.disabled,
    required this.onRemove,
  });

  final Contact contact;
  final String accessToken;
  final bool disabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final user = contact.user;
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
            ProfileAvatar(
              name: user.displayName,
              accessToken: accessToken,
              avatarUrl: user.avatarUrl,
              radius: 19,
            ),
            const SizedBox(width: 12),
            Expanded(child: _HeaderIdentity(contact: contact)),
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

class _HeaderIdentity extends StatelessWidget {
  const _HeaderIdentity({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final user = contact.user;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          '@${user.username}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ContactSummary extends StatelessWidget {
  const _ContactSummary({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileAvatar(
          name: user.displayName,
          accessToken: accessToken,
          avatarUrl: user.avatarUrl,
          radius: RetroMetrics.contactDetailAvatarRadius,
        ),
        const SizedBox(height: 12),
        Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          '@${user.username}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: RetroMetrics.spaceMedium),
        SizedBox(
          height: RetroMetrics.composerControlHeight,
          child: FilledButton.icon(
            key: const Key('contact-detail-message'),
            onPressed: disabled ? null : onMessage,
            style: FilledButton.styleFrom(
              minimumSize: const Size(112, RetroMetrics.composerControlHeight),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Message'),
          ),
        ),
      ],
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
