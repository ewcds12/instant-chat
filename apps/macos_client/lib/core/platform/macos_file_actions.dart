import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';

final localFileActionsProvider = Provider<LocalFileActions>((ref) {
  final language = ref.watch(appLanguageProvider).value ?? AppLanguage.english;
  return MacOSFileActions(AppLocalizations(language));
});

enum MessageFileAction { download }

abstract interface class LocalFileActions {
  Future<MessageFileAction?> chooseAction(String filename);

  Future<String?> chooseDownloadPath(String filename);

  Future<void> writeDownloadFile(String path, List<int> bytes);
}

class MacOSFileActions implements LocalFileActions {
  const MacOSFileActions([
    this.localizations = const AppLocalizations(AppLanguage.english),
  ]);

  final AppLocalizations localizations;

  @override
  Future<MessageFileAction?> chooseAction(String filename) async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'on run argv',
      '-e',
      'set fileName to item 1 of argv',
      '-e',
      'set promptText to item 2 of argv',
      '-e',
      'set cancelText to item 3 of argv',
      '-e',
      'set downloadText to item 4 of argv',
      '-e',
      'display dialog promptText & " " & fileName buttons {cancelText, downloadText} default button downloadText cancel button cancelText',
      '-e',
      'button returned of result',
      '-e',
      'end run',
      _safeFilename(filename),
      localizations.ui('Choose what to do with'),
      localizations.ui('Cancel'),
      localizations.ui('Download'),
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    return switch (result.stdout.toString().trim()) {
      final value when value == localizations.ui('Download') =>
        MessageFileAction.download,
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
      'set promptText to item 2 of argv',
      '-e',
      'set pickedFile to choose file name with prompt promptText default name defaultName',
      '-e',
      'POSIX path of pickedFile',
      '-e',
      'end run',
      _safeFilename(filename),
      localizations.ui('Save file as'),
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
