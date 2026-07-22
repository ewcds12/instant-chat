import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class RequestSection extends StatelessWidget {
  const RequestSection({
    required this.title,
    required this.countLabel,
    required this.requests,
    required this.accessToken,
    required this.isIncoming,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    super.key,
  });

  final String title;
  final String countLabel;
  final List<ContactRequest> requests;
  final String accessToken;
  final bool isIncoming;
  final bool disabled;
  final ValueChanged<ContactRequest> onAccept;
  final ValueChanged<ContactRequest> onDecline;
  final ValueChanged<ContactRequest> onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Text(
              countLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: RetroMetrics.spaceMedium),
        if (requests.isEmpty)
          _RequestEmptyState(incoming: isIncoming)
        else
          for (final request in requests)
            _RequestCard(
              request: request,
              accessToken: accessToken,
              incoming: isIncoming,
              disabled: disabled,
              onAccept: () => onAccept(request),
              onDecline: () => onDecline(request),
              onCancel: () => onCancel(request),
            ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.accessToken,
    required this.incoming,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  final ContactRequest request;
  final String accessToken;
  final bool incoming;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: SizedBox(
        height: RetroMetrics.contactRowHeight,
        child: Row(
          children: [
            ProfileAvatar(
              name: request.user.displayName,
              accessToken: accessToken,
              avatarUrl: request.user.avatarUrl,
              radius: RetroMetrics.contactDirectoryAvatarRadius,
            ),
            const SizedBox(width: 12),
            Expanded(child: _RequestIdentity(request: request)),
            if (incoming) ...[
              _RequestAction(
                label: 'Decline',
                onPressed: disabled ? null : onDecline,
              ),
              const SizedBox(width: RetroMetrics.spaceSmall),
              _RequestAction(
                label: 'Accept',
                onPressed: disabled ? null : onAccept,
                primary: true,
              ),
            ] else ...[
              Text(
                'Pending',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(width: RetroMetrics.spaceSmall),
              _RequestAction(
                label: 'Cancel',
                onPressed: disabled ? null : onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestAction extends StatelessWidget {
  const _RequestAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, RetroMetrics.composerControlHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: Theme.of(context).textTheme.labelLarge,
          )
        : TextButton.styleFrom(
            minimumSize: const Size(0, RetroMetrics.composerControlHeight),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: Theme.of(context).textTheme.labelLarge,
          );
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : TextButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

class _RequestIdentity extends StatelessWidget {
  const _RequestIdentity({required this.request});

  final ContactRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          request.user.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '@${request.user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RequestEmptyState extends StatelessWidget {
  const _RequestEmptyState({required this.incoming});

  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RetroMetrics.spaceSmall),
      child: Row(
        children: [
          Icon(
            incoming ? Icons.inbox_outlined : Icons.send_outlined,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: RetroMetrics.spaceSmall),
          Text(
            incoming ? 'No incoming requests.' : 'No sent requests.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
