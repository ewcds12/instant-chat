import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localImagePickerProvider = Provider<LocalImagePicker>((ref) {
  return const MacOSImagePicker();
});

abstract interface class LocalImagePicker {
  Future<String?> pickImagePath();
}

class MacOSImagePicker implements LocalImagePicker {
  const MacOSImagePicker();

  @override
  Future<String?> pickImagePath() async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'set pickedImage to choose file of type {"public.image"} with prompt "Choose an image to send"',
      '-e',
      'POSIX path of pickedImage',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }
}
