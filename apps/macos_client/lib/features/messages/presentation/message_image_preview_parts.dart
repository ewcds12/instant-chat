part of 'message_image_preview.dart';

class _PreviewToolbar extends StatelessWidget {
  const _PreviewToolbar({
    required this.index,
    required this.total,
    required this.onClose,
    required this.onDownload,
    required this.isDownloading,
  });

  final int index;
  final int total;
  final VoidCallback onClose;
  final Future<void> Function() onDownload;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${index + 1} of $total',
            key: const Key('message-image-preview-counter'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Tooltip(
                message: 'Download image',
                child: TextButton.icon(
                  key: const Key('message-image-preview-download'),
                  onPressed: isDownloading ? null : onDownload,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    backgroundColor: colors.surface.withValues(alpha: 0.56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 17),
                  label: const Text('Download'),
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('message-image-preview-close'),
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      color: colors.onSurface,
      style: IconButton.styleFrom(
        backgroundColor: colors.surface.withValues(alpha: 0.78),
        fixedSize: const Size(42, 42),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      height: 360,
      color: color,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 32),
    );
  }
}
