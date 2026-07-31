const maximumDroppedImageBytes = 15 * 1024 * 1024;
const maximumDroppedFileBytes = 2 * 1024 * 1024 * 1024;

const _supportedImageExtensions = {'.gif', '.jpeg', '.jpg', '.png', '.webp'};

bool messageDropPathIsImage(String path) {
  final lowerPath = path.toLowerCase();
  return _supportedImageExtensions.any(lowerPath.endsWith);
}

String? messageDropSizeError(String path, int byteSize) {
  if (messageDropPathIsImage(path)) {
    return byteSize > maximumDroppedImageBytes
        ? 'Images must be 15 MB or smaller.'
        : null;
  }
  return byteSize > maximumDroppedFileBytes
      ? 'Files must be 2 GB or smaller.'
      : null;
}
