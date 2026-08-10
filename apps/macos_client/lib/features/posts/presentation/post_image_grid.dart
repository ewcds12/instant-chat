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
      return AspectRatio(
        aspectRatio: 2.65,
        child: _PostPhoto(
          image: images.first,
          accessToken: accessToken,
          allImages: images,
        ),
      );
    }
    final visible = images.take(4).toList(growable: false);
    return SizedBox(
      height: visible.length == 2 ? 180 : 300,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: visible.length == 2 ? 1 : 1.35,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) => _PostPhoto(
          image: visible[index],
          accessToken: accessToken,
          allImages: visible,
        ),
      ),
    );
  }
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({
    required this.image,
    required this.accessToken,
    required this.allImages,
  });

  final PublicPostImage image;
  final String accessToken;
  final List<PublicPostImage> allImages;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteUrl(image.url);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(RetroMetrics.corner),
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
          fit: BoxFit.cover,
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
