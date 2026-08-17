import 'package:flutter/material.dart';
import 'package:instant_chat/core/config/app_config.dart';
import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';

part 'post_photo_viewer.dart';

class PostImageGrid extends StatelessWidget {
  const PostImageGrid({
    required this.images,
    required this.accessToken,
    this.onDownloadImage,
    super.key,
  });

  final List<PublicPostImage> images;
  final String accessToken;
  final Future<void> Function(PublicPostImage image)? onDownloadImage;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    if (images.length == 1) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final proportionalWidth =
              constraints.maxWidth * RetroMetrics.exploreSingleImageWidthFactor;
          final width =
              proportionalWidth > RetroMetrics.exploreSingleImageMaxWidth
              ? RetroMetrics.exploreSingleImageMaxWidth
              : proportionalWidth;
          return Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              key: const Key('post-single-image-frame'),
              constraints: BoxConstraints(
                minWidth: width,
                maxWidth: width,
                maxHeight: RetroMetrics.exploreSingleImageMaxHeight,
              ),
              child: _PostPhoto(
                key: const Key('post-image-0'),
                image: images.first,
                accessToken: accessToken,
                allImages: images,
                onDownloadImage: onDownloadImage,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
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
      child: _MultiImageLayout(
        images: visible,
        accessToken: accessToken,
        onDownloadImage: onDownloadImage,
      ),
    );
  }
}

class _MultiImageLayout extends StatelessWidget {
  const _MultiImageLayout({
    required this.images,
    required this.accessToken,
    required this.onDownloadImage,
  });

  final List<PublicPostImage> images;
  final String accessToken;
  final Future<void> Function(PublicPostImage image)? onDownloadImage;

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
      onDownloadImage: onDownloadImage,
      rounded: false,
    );
  }
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({
    required this.image,
    required this.accessToken,
    required this.allImages,
    required this.onDownloadImage,
    this.fit = BoxFit.cover,
    this.rounded = true,
    super.key,
  });

  final PublicPostImage image;
  final String accessToken;
  final List<PublicPostImage> allImages;
  final Future<void> Function(PublicPostImage image)? onDownloadImage;
  final BoxFit fit;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final url = _absoluteUrl(image.url);
    final borderRadius = rounded
        ? BorderRadius.circular(RetroMetrics.corner)
        : BorderRadius.zero;
    return Material(
      type: MaterialType.transparency,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPostPhotoViewer(
          context: context,
          initialImage: image,
          images: allImages,
          accessToken: accessToken,
          onDownloadImage: onDownloadImage,
        ),
        child: Image.network(
          url,
          width: double.infinity,
          fit: fit,
          headers: bearerAuthorization(accessToken),
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 24)),
        ),
      ),
    );
  }
}

String _absoluteUrl(String path) {
  return Uri.parse(AppConfig.apiBaseUrl).resolve(path).toString();
}

String postImageDownloadFilename(PublicPostImage image) {
  final extension = switch (image.contentType) {
    'image/gif' => '.gif',
    'image/heic' => '.heic',
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'image/tiff' => '.tiff',
    'image/webp' => '.webp',
    _ => '.img',
  };
  return 'image-${image.id}$extension';
}
