import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';

part 'profile_photo_crop.dart';

Future<String?> showProfilePhotoCropper({
  required BuildContext context,
  required String imagePath,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProfilePhotoCropper(imagePath: imagePath),
  );
}

class _ProfilePhotoCropper extends StatefulWidget {
  const _ProfilePhotoCropper({required this.imagePath});

  final String imagePath;

  @override
  State<_ProfilePhotoCropper> createState() => _ProfilePhotoCropperState();
}

class _ProfilePhotoCropperState extends State<_ProfilePhotoCropper> {
  ui.Image? _image;
  Rect? _cropRect;
  var _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      key: const Key('profile-photo-cropper'),
      insetPadding: const EdgeInsets.all(RetroMetrics.spaceLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: RetroMetrics.maxProfilePhotoCropPanelWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(RetroMetrics.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Crop photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: RetroMetrics.spaceMedium),
              _cropArea(colors),
              const SizedBox(height: RetroMetrics.spaceMedium),
              Text(
                _errorMessage ??
                    'Drag the circle to choose your profile photo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _errorMessage == null
                      ? colors.onSurfaceVariant
                      : colors.error,
                ),
              ),
              const SizedBox(height: RetroMetrics.spaceMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('profile-photo-crop-cancel'),
                    onPressed: _isExporting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: RetroMetrics.spaceSmall),
                  FilledButton(
                    key: const Key('profile-photo-crop-confirm'),
                    onPressed: _image == null || _isExporting ? null : _confirm,
                    child: Text(_isExporting ? 'Preparing…' : 'Use photo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cropArea(ColorScheme colors) {
    final image = _image;
    if (image == null) {
      return SizedBox(
        width: RetroMetrics.profilePhotoCropPreviewSize,
        height: RetroMetrics.profilePhotoCropPreviewSize,
        child: Center(
          child: _errorMessage == null
              ? const CircularProgressIndicator()
              : Icon(
                  Icons.broken_image_outlined,
                  color: colors.error,
                  size: 34,
                ),
        ),
      );
    }
    return _CropCanvas(
      image: image,
      cropRect: _cropRect,
      onCropChanged: (cropRect) => setState(() => _cropRect = cropRect),
    );
  }

  Future<void> _loadImage() async {
    try {
      final image = await _decodeImage(widget.imagePath);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } on Exception {
      if (mounted) {
        setState(() => _errorMessage = 'This image could not be opened.');
      }
    }
  }

  Future<void> _confirm() async {
    final image = _image;
    if (image == null) {
      return;
    }
    final imageRect = profilePhotoImageRect(image);
    final cropRect = _cropRect ?? initialProfilePhotoCropRect(imageRect);
    setState(() => _isExporting = true);
    try {
      final path = await cropProfilePhoto(
        image: image,
        cropRect: cropRect,
        imageRect: imageRect,
      );
      if (mounted) {
        Navigator.of(context).pop(path);
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'The cropped photo could not be prepared.';
        });
      }
    }
  }
}

class _CropCanvas extends StatelessWidget {
  const _CropCanvas({
    required this.image,
    required this.cropRect,
    required this.onCropChanged,
  });

  final ui.Image image;
  final Rect? cropRect;
  final ValueChanged<Rect> onCropChanged;

  @override
  Widget build(BuildContext context) {
    final imageRect = profilePhotoImageRect(image);
    final currentCrop = cropRect ?? initialProfilePhotoCropRect(imageRect);
    return SizedBox(
      width: RetroMetrics.profilePhotoCropPreviewSize,
      height: RetroMetrics.profilePhotoCropPreviewSize,
      child: GestureDetector(
        onPanUpdate: (details) => onCropChanged(
          moveProfilePhotoCropRect(currentCrop, details.delta, imageRect),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(RetroMetrics.corner),
              ),
            ),
            Positioned.fromRect(
              rect: imageRect,
              child: RawImage(image: image, fit: BoxFit.fill),
            ),
            CustomPaint(painter: _CropOverlayPainter(cropRect: currentCrop)),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.cropRect});

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(cropRect);
    canvas.drawPath(mask, Paint()..color = const Color(0x88000000));
    canvas.drawOval(
      cropRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}

Future<ui.Image> _decodeImage(String imagePath) async {
  final codec = await ui.instantiateImageCodec(
    await File(imagePath).readAsBytes(),
  );
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}
