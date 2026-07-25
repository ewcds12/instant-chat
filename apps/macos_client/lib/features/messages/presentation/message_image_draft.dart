import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:instant_chat/core/platform/macos_clipboard_image.dart';

class MessageImageDraft extends ChangeNotifier {
  MessageImageDraft(this._clipboardImages) {
    if (_clipboardImages case ClipboardImagePasteEvents source) {
      _pasteSubscription = source.pastedImages.listen(_stage);
    }
  }

  final LocalClipboardImage _clipboardImages;
  StreamSubscription<ClipboardImage>? _pasteSubscription;
  ClipboardImage? _image;
  var _active = true;

  ClipboardImage? get image => _image;

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
    await _stage(next);
    return true;
  }

  void remove([ClipboardImage? expected]) {
    final current = _image;
    if (current == null || (expected != null && expected != current)) {
      return;
    }
    _image = null;
    notifyListeners();
    unawaited(_clipboardImages.release(current));
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
    if (_image case final image?) {
      unawaited(_clipboardImages.release(image));
      _image = null;
    }
    super.dispose();
  }

  Future<void> _stage(ClipboardImage next) async {
    if (!_active) {
      await _clipboardImages.release(next);
      return;
    }
    final previous = _image;
    _image = next;
    notifyListeners();
    if (previous != null && previous.path != next.path) {
      unawaited(_clipboardImages.release(previous));
    }
  }
}
