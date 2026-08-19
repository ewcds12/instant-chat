import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final macOSUrlLauncherProvider = Provider<MacOSUrlLauncher>((ref) {
  return const MacOSUrlLauncher();
});

final localUrlLauncherProvider = Provider<LocalUrlLauncher>((ref) {
  return ref.watch(macOSUrlLauncherProvider);
});

final linkOpeningPreferenceProvider = Provider<LinkOpeningPreference>((ref) {
  return ref.watch(macOSUrlLauncherProvider);
});

abstract interface class LocalUrlLauncher {
  Future<void> open(Uri url);
}

abstract interface class LinkOpeningPreference {
  Future<bool> getOpenLinksInDefaultBrowser();

  Future<void> setOpenLinksInDefaultBrowser(bool enabled);
}

class MacOSUrlLauncher implements LocalUrlLauncher, LinkOpeningPreference {
  const MacOSUrlLauncher([
    this._channel = const MethodChannel('instant_chat/url_launcher'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> open(Uri url) async {
    if (url.scheme != 'http' && url.scheme != 'https') {
      throw ArgumentError.value(url, 'url', 'Only web links can be opened.');
    }
    await _channel.invokeMethod<void>('open', {'url': url.toString()});
  }

  @override
  Future<bool> getOpenLinksInDefaultBrowser() async {
    final value = await _channel.invokeMethod<bool>(
      'getOpenLinksInDefaultBrowser',
    );
    return value ?? true;
  }

  @override
  Future<void> setOpenLinksInDefaultBrowser(bool enabled) {
    return _channel.invokeMethod<void>('setOpenLinksInDefaultBrowser', {
      'enabled': enabled,
    });
  }
}
