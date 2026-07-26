import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/contacts/domain/contact_request.dart';

const contactRequestDrawerRowHeight = RetroMetrics.contactRowHeight;

class ContactRequestDrawerRow extends StatelessWidget {
  const ContactRequestDrawerRow({
    required this.request,
    required this.disabled,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final ContactRequest request;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('contact-request-row-${request.id}'),
      height: contactRequestDrawerRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${request.user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _RequestButton(
              key: ValueKey('contact-request-decline-${request.id}'),
              label: 'Decline',
              onPressed: disabled ? null : onDecline,
              width: 62,
            ),
            const SizedBox(width: 8),
            _RequestButton(
              key: ValueKey('contact-request-accept-${request.id}'),
              label: 'Accept',
              onPressed: disabled ? null : onAccept,
              width: 58,
              primary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({
    required this.label,
    required this.onPressed,
    required this.width,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(width, RetroMetrics.composerSendDiameter),
      ),
      maximumSize: WidgetStatePropertyAll(
        Size(width, RetroMetrics.composerSendDiameter),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.onSurfaceVariant.withValues(alpha: 0.38)
            : primary
            ? colors.onPrimary
            : colors.onSurfaceVariant,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.surfaceContainer
            : primary
            ? colors.primary
            : colors.surfaceContainerLowest,
      ),
      side: WidgetStatePropertyAll(
        primary ? BorderSide.none : BorderSide(color: colors.outlineVariant),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RetroMetrics.corner),
        ),
      ),
    );
    final child = Text(label, maxLines: 1, softWrap: false);
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
