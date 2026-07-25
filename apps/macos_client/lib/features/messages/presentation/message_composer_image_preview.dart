import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageComposerImagePreview extends StatelessWidget {
  const MessageComposerImagePreview({
    required this.imagePath,
    required this.disabled,
    required this.onRemove,
    super.key,
  });

  final String imagePath;
  final bool disabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RetroMetrics.composerImagePreviewInset,
          RetroMetrics.composerImagePreviewInset,
          RetroMetrics.composerImagePreviewInset,
          0,
        ),
        child: SizedBox.square(
          key: const Key('message-composer-image-preview'),
          dimension: RetroMetrics.composerImagePreviewSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    RetroMetrics.composerImagePreviewRadius,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: 'Remove photo',
                  child: SizedBox.square(
                    dimension: RetroMetrics.composerImageRemoveDiameter,
                    child: Material(
                      color: colors.scrim.withValues(alpha: 0.78),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('message-composer-image-remove'),
                        customBorder: const CircleBorder(),
                        onTap: disabled ? null : onRemove,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
