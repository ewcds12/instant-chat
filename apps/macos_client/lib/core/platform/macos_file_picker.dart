import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';

final localFilePickerProvider = Provider<LocalFilePicker>((ref) {
  final language = ref.watch(appLanguageProvider).value ?? AppLanguage.english;
  return MacOSFilePicker(AppLocalizations(language));
});

abstract interface class LocalFilePicker {
  Future<String?> pickFilePath();
}

class MacOSFilePicker implements LocalFilePicker {
  const MacOSFilePicker([
    this.localizations = const AppLocalizations(AppLanguage.english),
  ]);

  final AppLocalizations localizations;

  @override
  Future<String?> pickFilePath() async {
    final result = await Process.run('/usr/bin/osascript', [
      '-e',
      'on run argv',
      '-e',
      'set pickedFile to choose file with prompt (item 1 of argv)',
      '-e',
      'POSIX path of pickedFile',
      '-e',
      'end run',
      localizations.ui('Choose a file to send'),
    ]);
    if (result.exitCode != 0) {
      return null;
    }
    final path = result.stdout.toString().trim();
    return path.isEmpty ? null : path;
  }
}
