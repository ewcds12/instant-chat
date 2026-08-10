part of 'post_image_grid.dart';

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({
    required this.initialIndex,
    required this.images,
    required this.accessToken,
  });

  final int initialIndex;
  final List<PublicPostImage> images;
  final String accessToken;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late var _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(56),
      child: SizedBox(
        width: 820,
        height: 620,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.all(24),
                child: Image.network(
                  _absoluteUrl(widget.images[index].url),
                  fit: BoxFit.contain,
                  headers: bearerAuthorization(widget.accessToken),
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 32),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                '${_index + 1} of ${widget.images.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            if (_index > 0)
              Positioned(
                left: RetroMetrics.explorePhotoNavigationInset,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _PhotoNavigationButton(
                    key: const Key('post-photo-previous'),
                    tooltip: 'Previous photo',
                    icon: Icons.chevron_left_rounded,
                    onPressed: _showPrevious,
                  ),
                ),
              ),
            if (_index < widget.images.length - 1)
              Positioned(
                right: RetroMetrics.explorePhotoNavigationInset,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _PhotoNavigationButton(
                    key: const Key('post-photo-next'),
                    tooltip: 'Next photo',
                    icon: Icons.chevron_right_rounded,
                    onPressed: _showNext,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPrevious() {
    _controller.previousPage(
      duration: RetroMetrics.explorePhotoNavigationDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _showNext() {
    _controller.nextPage(
      duration: RetroMetrics.explorePhotoNavigationDuration,
      curve: Curves.easeOutCubic,
    );
  }
}

class _PhotoNavigationButton extends StatelessWidget {
  const _PhotoNavigationButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      tooltip: tooltip,
      color: colors.onSurface,
      style: IconButton.styleFrom(
        backgroundColor: colors.surface.withValues(alpha: 0.84),
        fixedSize: const Size.square(RetroMetrics.explorePhotoNavigationSize),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
