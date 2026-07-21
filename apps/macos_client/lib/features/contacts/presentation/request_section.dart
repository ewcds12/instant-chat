import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';
import 'package:instant_chat/features/profile/presentation/profile_avatar.dart';

class RequestSection extends StatelessWidget {
  const RequestSection({
    required this.title,
    required this.description,
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
  final String description;
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: RetroMetrics.spaceSmall),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: RetroMetrics.spaceMedium),
        if (requests.isEmpty)
          _RequestEmptyState(incoming: isIncoming)
        else
          for (final request in requests) ...[
            _RequestCard(
              request: request,
              accessToken: accessToken,
              incoming: isIncoming,
              disabled: disabled,
              onAccept: () => onAccept(request),
              onDecline: () => onDecline(request),
              onCancel: () => onCancel(request),
            ),
            const SizedBox(height: RetroMetrics.spaceSmall),
          ],
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
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(RetroMetrics.corner),
      child: Ink(
        padding: const EdgeInsets.all(RetroMetrics.spaceMedium),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(RetroMetrics.corner),
        ),
        child: Row(
          children: [
            ProfileAvatar(
              name: request.user.displayName,
              accessToken: accessToken,
              avatarUrl: request.user.avatarUrl,
              radius: RetroMetrics.contactAvatarRadius,
            ),
            const SizedBox(width: RetroMetrics.spaceMedium),
            Expanded(child: _RequestIdentity(request: request)),
            if (incoming) ...[
              TextButton(
                onPressed: disabled ? null : onDecline,
                child: const Text('Decline'),
              ),
              const SizedBox(width: RetroMetrics.spaceSmall),
              FilledButton(
                onPressed: disabled ? null : onAccept,
                child: const Text('Accept'),
              ),
            ] else ...[
              Text(
                'Pending',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: RetroMetrics.spaceSmall),
              TextButton(
                onPressed: disabled ? null : onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: Column(
        children: [
          Icon(
            incoming ? Icons.inbox_outlined : Icons.send_outlined,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: RetroMetrics.spaceSmall),
          Text(
            incoming ? 'No incoming requests' : 'No sent requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RetroMetrics.spaceSmall),
          Text(
            incoming
                ? 'New contact requests will appear here.'
                : 'Requests you send will appear here while they are pending.',
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
