import 'package:flutter/material.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class MessageImageView extends StatelessWidget {
  const MessageImageView({
    required this.image,
    required this.accessToken,
    this.openKey,
    this.onOpen,
    super.key,
  });

  final MessageImage image;
  final String accessToken;
  final Key? openKey;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 320),
          child: Image.network(
            messageImageUrl(image),
            headers: bearerAuthorization(accessToken),
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return const _ImagePlaceholder(
                icon: Icons.image_outlined,
                label: 'Loading image…',
              );
            },
            errorBuilder: (context, _, _) => const _ImagePlaceholder(
              icon: Icons.broken_image_outlined,
              label: 'Image unavailable',
            ),
          ),
        ),
      ),
    );
    return MouseRegion(
      cursor: onOpen == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        key: openKey,
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: content,
      ),
    );
  }
}

String messageImageUrl(MessageImage image) {
  return Uri.parse(AppConfig.apiBaseUrl).resolve(image.url).toString();
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      height: 150,
      color: colors.surfaceContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
