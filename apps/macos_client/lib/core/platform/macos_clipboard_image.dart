import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localClipboardImageProvider = Provider<LocalClipboardImage>((ref) {
  final clipboard = MacOSClipboardImage();
  ref.onDispose(clipboard.dispose);
  return clipboard;
});

class ClipboardImage {
  const ClipboardImage({required this.path, required this.isTemporary});

  final String path;
  final bool isTemporary;
}

abstract interface class LocalClipboardImage {
  Future<ClipboardImage?> read();

  Future<void> release(ClipboardImage image);
}

abstract interface class ClipboardImagePasteEvents {
  Stream<ClipboardImage> get pastedImages;

  Future<void> setPasteEnabled(bool enabled);
}

class MacOSClipboardImage
    implements LocalClipboardImage, ClipboardImagePasteEvents {
  MacOSClipboardImage([
    this._channel = const MethodChannel('instant_chat/clipboard'),
  ]) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final _pastedImages = StreamController<ClipboardImage>.broadcast();

  @override
  Stream<ClipboardImage> get pastedImages => _pastedImages.stream;

  @override
  Future<void> setPasteEnabled(bool enabled) {
    return _channel.invokeMethod<void>('setPasteEnabled', enabled);
  }

  @override
  Future<ClipboardImage?> read() async {
    final value = await _channel.invokeMapMethod<String, Object?>('readImage');
    if (value == null) {
      return null;
    }
    final path = value['path'];
    final isTemporary = value['is_temporary'];
    if (path is! String || path.isEmpty || isTemporary is! bool) {
      throw const FormatException('Clipboard image response is invalid.');
    }
    return ClipboardImage(path: path, isTemporary: isTemporary);
  }

  @override
  Future<void> release(ClipboardImage image) async {
    if (!image.isTemporary) {
      return;
    }
    final file = File(image.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_pastedImages.close());
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'imagePasted') {
      return;
    }
    final value = call.arguments;
    if (value is! Map) {
      return;
    }
    final image = _parseImage(value);
    if (image != null) {
      _pastedImages.add(image);
    }
  }

  ClipboardImage? _parseImage(Map<Object?, Object?> value) {
    final path = value['path'];
    final isTemporary = value['is_temporary'];
    if (path is! String || path.isEmpty || isTemporary is! bool) {
      return null;
    }
    return ClipboardImage(path: path, isTemporary: isTemporary);
  }
}
