part of 'profile_photo_cropper.dart';

Future<String> cropProfilePhoto({
  required ui.Image image,
  required Rect cropRect,
  required Rect imageRect,
}) async {
  final scale = image.width / imageRect.width;
  final sourceRect = Rect.fromLTWH(
    (cropRect.left - imageRect.left) * scale,
    (cropRect.top - imageRect.top) * scale,
    cropRect.width * scale,
    cropRect.height * scale,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final outputSize = RetroMetrics.profilePhotoCropOutputSize.toDouble();
  canvas.drawImageRect(
    image,
    sourceRect,
    Rect.fromLTWH(0, 0, outputSize, outputSize),
    Paint()..filterQuality = FilterQuality.high,
  );
  final outputImage = await recorder.endRecording().toImage(
    RetroMetrics.profilePhotoCropOutputSize,
    RetroMetrics.profilePhotoCropOutputSize,
  );
  try {
    final data = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const FormatException('Unable to encode cropped profile photo.');
    }
    final path =
        '${Directory.systemTemp.path}/instant_chat_avatar_'
        '${DateTime.now().microsecondsSinceEpoch}.png';
    await File(path).writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return path;
  } finally {
    outputImage.dispose();
  }
}

Rect profilePhotoImageRect(ui.Image image) {
  const size = RetroMetrics.profilePhotoCropPreviewSize;
  final scale =
      size / (image.width > image.height ? image.width : image.height);
  final width = image.width * scale;
  final height = image.height * scale;
  return Rect.fromCenter(
    center: const Offset(size / 2, size / 2),
    width: width,
    height: height,
  );
}

Rect initialProfilePhotoCropRect(Rect imageRect) {
  final size = imageRect.width < imageRect.height
      ? imageRect.width
      : imageRect.height;
  return Rect.fromCenter(center: imageRect.center, width: size, height: size);
}

Rect moveProfilePhotoCropRect(Rect cropRect, Offset delta, Rect imageRect) {
  final left = (cropRect.left + delta.dx)
      .clamp(imageRect.left, imageRect.right - cropRect.width)
      .toDouble();
  final top = (cropRect.top + delta.dy)
      .clamp(imageRect.top, imageRect.bottom - cropRect.height)
      .toDouble();
  return Rect.fromLTWH(left, top, cropRect.width, cropRect.height);
}
