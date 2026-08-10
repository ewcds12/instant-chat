import 'package:flutter/material.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';

class PostImageGrid extends StatelessWidget {
  const PostImageGrid({
    required this.images,
    required this.accessToken,
    super.key,
  });

  final List<PublicPostImage> images;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    if (images.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          key: const Key('post-single-image-frame'),
          constraints: const BoxConstraints(
            maxWidth: RetroMetrics.exploreSingleImageMaxWidth,
            maxHeight: RetroMetrics.exploreSingleImageMaxHeight,
          ),
          child: _PostPhoto(
            key: const Key('post-image-0'),
            image: images.first,
            accessToken: accessToken,
            allImages: images,
            fit: BoxFit.contain,
            expandWidth: false,
          ),
        ),
      );
    }
    final visible = images.take(4).toList(growable: false);
    final height = visible.length == 2
        ? RetroMetrics.exploreDoubleImageHeight
        : RetroMetrics.exploreMosaicImageHeight;
    return Container(
      key: const Key('post-multi-image-frame'),
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(RetroMetrics.corner),
      ),
      child: _MultiImageLayout(images: visible, accessToken: accessToken),
    );
  }
}

class _MultiImageLayout extends StatelessWidget {
  const _MultiImageLayout({required this.images, required this.accessToken});

  final List<PublicPostImage> images;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    final gap = RetroMetrics.exploreImageGap;
    if (images.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _photo(0)),
          SizedBox(width: gap),
          Expanded(child: _photo(1)),
        ],
      );
    }
    if (images.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _photo(0)),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _photo(1)),
                SizedBox(height: gap),
                Expanded(child: _photo(2)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _photo(0)),
              SizedBox(width: gap),
              Expanded(child: _photo(1)),
            ],
          ),
        ),
        SizedBox(height: gap),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _photo(2)),
              SizedBox(width: gap),
              Expanded(child: _photo(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photo(int index) {
    return _PostPhoto(
      key: Key('post-image-$index'),
      image: images[index],
      accessToken: accessToken,
      allImages: images,
      rounded: false,
    );
  }
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({
    required this.image,
    required this.accessToken,
    required this.allImages,
    this.fit = BoxFit.cover,
    this.expandWidth = true,
    this.rounded = true,
    super.key,
  });

  final PublicPostImage image;
  final String accessToken;
  final List<PublicPostImage> allImages;
  final BoxFit fit;
  final bool expandWidth;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteUrl(image.url);
    final borderRadius = rounded
        ? BorderRadius.circular(RetroMetrics.corner)
        : BorderRadius.zero;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => _PhotoViewer(
            initialIndex: allImages.indexOf(image),
            images: allImages,
            accessToken: accessToken,
          ),
        ),
        child: Image.network(
          url,
          width: expandWidth ? double.infinity : null,
          fit: fit,
          headers: bearerAuthorization(accessToken),
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 24)),
        ),
      ),
    );
  }
}

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
          ],
        ),
      ),
    );
  }
}

String _absoluteUrl(String path) {
  return Uri.parse(AppConfig.apiBaseUrl).resolve(path).toString();
}
