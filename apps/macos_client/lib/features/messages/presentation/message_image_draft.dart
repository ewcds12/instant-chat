import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/platform/macos_clipboard_image.dart';

class MessageImageDraft extends ChangeNotifier {
  MessageImageDraft(this._clipboardImages, {this.onLimitReached}) {
    if (_clipboardImages case ClipboardImagePasteEvents source) {
      _pasteSubscription = source.pastedImages.listen(_stage);
    }
  }

  static const maximumImages = 3;

  final LocalClipboardImage _clipboardImages;
  final VoidCallback? onLimitReached;
  StreamSubscription<ClipboardImage>? _pasteSubscription;
  final List<ClipboardImage> _images = [];
  var _active = true;

  List<ClipboardImage> get images => List.unmodifiable(_images);

  Future<bool> paste() async {
    ClipboardImage? next;
    try {
      next = await _clipboardImages.read();
    } on PlatformException {
      return false;
    } on FormatException {
      return false;
    }
    if (next == null) {
      return false;
    }
    return _stage(next);
  }

  void remove(String path) {
    final index = _images.indexWhere((image) => image.path == path);
    if (index < 0) {
      return;
    }
    final removed = _images.removeAt(index);
    notifyListeners();
    unawaited(_clipboardImages.release(removed));
  }

  void clear() {
    if (_images.isEmpty) {
      return;
    }
    final removed = List<ClipboardImage>.of(_images);
    _images.clear();
    notifyListeners();
    for (final image in removed) {
      unawaited(_clipboardImages.release(image));
    }
  }

  void setPasteEnabled(bool enabled) {
    if (_clipboardImages case ClipboardImagePasteEvents source) {
      unawaited(source.setPasteEnabled(enabled));
    }
  }

  @override
  void dispose() {
    _active = false;
    setPasteEnabled(false);
    unawaited(_pasteSubscription?.cancel());
    for (final image in _images) {
      unawaited(_clipboardImages.release(image));
    }
    _images.clear();
    super.dispose();
  }

  Future<bool> _stage(ClipboardImage next) async {
    if (!_active) {
      await _clipboardImages.release(next);
      return true;
    }
    if (_images.any((image) => image.path == next.path)) {
      return true;
    }
    if (_images.length >= maximumImages) {
      await _clipboardImages.release(next);
      onLimitReached?.call();
      return true;
    }
    _images.add(next);
    notifyListeners();
    return true;
  }
}
