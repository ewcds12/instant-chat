import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class ContactRequestNotificationDot extends StatelessWidget {
  const ContactRequestNotificationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'New contact request',
      child: Container(
        key: const Key('contact-request-notification-dot'),
        width: RetroMetrics.contactRequestNotificationDotDiameter,
        height: RetroMetrics.contactRequestNotificationDotDiameter,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
