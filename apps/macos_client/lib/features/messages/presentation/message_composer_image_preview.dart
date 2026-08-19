import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

class MessageComposerImagePreviews extends StatelessWidget {
  const MessageComposerImagePreviews({
    required this.imagePaths,
    required this.disabled,
    required this.onRemove,
    super.key,
  });

  final List<String> imagePaths;
  final bool disabled;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RetroMetrics.composerImagePreviewInset,
        RetroMetrics.composerImagePreviewInset,
        RetroMetrics.composerImagePreviewInset,
        0,
      ),
      child: Wrap(
        key: const Key('message-composer-image-previews'),
        spacing: RetroMetrics.spaceSmall,
        runSpacing: RetroMetrics.spaceSmall,
        children: [
          for (final imagePath in imagePaths)
            _ImagePreview(
              imagePath: imagePath,
              disabled: disabled,
              onRemove: () => onRemove(imagePath),
            ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imagePath,
    required this.disabled,
    required this.onRemove,
  });

  final String imagePath;
  final bool disabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      key: ValueKey('message-composer-image-preview:$imagePath'),
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
              message: context.l10n.ui('Remove photo'),
              child: SizedBox.square(
                dimension: RetroMetrics.composerImageRemoveDiameter,
                child: Material(
                  color: colors.scrim.withValues(alpha: 0.78),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('message-composer-image-remove:$imagePath'),
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
    );
  }
}
