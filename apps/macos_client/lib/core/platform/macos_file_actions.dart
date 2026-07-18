import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localFileActionsProvider = Provider<LocalFileActions>((ref) {
  return const MacOSFileActions();
});

enum MessageFileAction { download }

abstract interface class LocalFileActions {
  Future<MessageFileAction?> chooseAction(String filename);

  Future<String?> chooseDownloadPath(String filename);

  Future<void> writeDownloadFile(String path, List<int> bytes);
}

class MacOSFileActions implements LocalFileActions {
  const MacOSFileActions();

  @override
  Future<MessageFileAction?> chooseAction(String filename) async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'on run argv',
      '-e',
      'set fileName to item 1 of argv',
      '-e',
      'display dialog "Choose what to do with " & fileName buttons {"Cancel", "Download"} default button "Download" cancel button "Cancel"',
      '-e',
      'button returned of result',
      '-e',
      'end run',
      _safeFilename(filename),
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    return switch (result.stdout.toString().trim()) {
      'Download' => MessageFileAction.download,
      _ => null,
    };
  }

  @override
  Future<String?> chooseDownloadPath(String filename) async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'on run argv',
      '-e',
      'set defaultName to item 1 of argv',
      '-e',
      'set pickedFile to choose file name with prompt "Save file as" default name defaultName',
      '-e',
      'POSIX path of pickedFile',
      '-e',
      'end run',
      _safeFilename(filename),
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }

  @override
  Future<void> writeDownloadFile(String path, List<int> bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}

String _safeFilename(String filename) {
  final basename = filename.split(RegExp(r'[/\\]')).last.trim();
  final safe = basename.replaceAll(RegExp(r'[:\u0000-\u001F]'), '_');
  return safe.isEmpty ? 'download' : safe;
}
