import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/profile/presentation/profile_photo_cropper.dart';

void main() {
  test('exports a square PNG from the selected image region', () async {
    final sourceImage = await _sourceImage();
    addTearDown(sourceImage.dispose);

    final path = await cropProfilePhoto(
      image: sourceImage,
      cropRect: const ui.Rect.fromLTWH(50, 0, 100, 100),
      imageRect: const ui.Rect.fromLTWH(0, 0, 200, 100),
    );
    addTearDown(() => File(path).delete());

    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final croppedImage = (await codec.getNextFrame()).image;
    addTearDown(croppedImage.dispose);
    addTearDown(codec.dispose);

    expect(croppedImage.width, 512);
    expect(croppedImage.height, 512);
  });
}

Future<ui.Image> _sourceImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF2F6FE4), ui.BlendMode.src);
  return recorder.endRecording().toImage(200, 100);
}
