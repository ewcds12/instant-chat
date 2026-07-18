import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localFilePickerProvider = Provider<LocalFilePicker>((ref) {
  return const MacOSFilePicker();
});

abstract interface class LocalFilePicker {
  Future<String?> pickFilePath();
}

class MacOSFilePicker implements LocalFilePicker {
  const MacOSFilePicker();

  @override
  Future<String?> pickFilePath() async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'set pickedFile to choose file with prompt "Choose a file to send"',
      '-e',
      'POSIX path of pickedFile',
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }
}
