part of 'post_image_grid.dart';

Future<void> _showPostPhotoViewer({
  required BuildContext context,
  required PublicPostImage initialImage,
  required List<PublicPostImage> images,
  required String accessToken,
  required Future<void> Function(PublicPostImage image)? onDownloadImage,
}) {
  final previewImages = images.map(_asMessageImage).toList(growable: false);
  return showMessageImagePreview(
    context: context,
    images: previewImages,
    initialImage: _asMessageImage(initialImage),
    accessToken: accessToken,
    onDownload: onDownloadImage == null
        ? null
        : (previewImage) {
            final image = images.firstWhere(
              (candidate) => candidate.id == previewImage.id,
            );
            return onDownloadImage(image);
          },
  );
}

MessageImage _asMessageImage(PublicPostImage image) {
  return MessageImage(
    id: image.id,
    url: image.url,
    contentType: image.contentType,
    byteSize: image.byteSize,
  );
}
