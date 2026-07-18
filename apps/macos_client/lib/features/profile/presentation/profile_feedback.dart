import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class ProfileFeedback extends StatelessWidget {
  const ProfileFeedback({
    required this.message,
    required this.isError,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colors.errorContainer
        : colors.inverseSurface;
    final foregroundColor = isError
        ? colors.onErrorContainer
        : colors.onInverseSurface;
    return DecoratedBox(
      key: const Key('profile-feedback'),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RetroMetrics.spaceMedium,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: foregroundColor,
              size: 18,
            ),
            const SizedBox(width: RetroMetrics.spaceSmall),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
