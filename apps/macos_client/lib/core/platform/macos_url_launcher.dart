import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localUrlLauncherProvider = Provider<LocalUrlLauncher>((ref) {
  return const MacOSUrlLauncher();
});

abstract interface class LocalUrlLauncher {
  Future<void> open(Uri url);
}

class MacOSUrlLauncher implements LocalUrlLauncher {
  const MacOSUrlLauncher();

  @override
  Future<void> open(Uri url) async {
    if (url.scheme != 'http' && url.scheme != 'https') {
      throw ArgumentError.value(url, 'url', 'Only web links can be opened.');
    }
    final result = await Process.run('/usr/bin/open', [url.toString()]);
    if (result.exitCode != 0) {
      throw const FileSystemException('The link could not be opened.');
    }
  }
}
