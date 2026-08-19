import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsWindowControllerProvider = Provider<SettingsWindowController>(
  (ref) => const MacOSSettingsWindowController(),
);

abstract interface class SettingsWindowController {
  Future<void> open();
}

class MacOSSettingsWindowController implements SettingsWindowController {
  const MacOSSettingsWindowController([
    this._channel = const MethodChannel('instant_chat/settings_window'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>('open');
    } on MissingPluginException {
      // Widget tests do not attach the native macOS runner.
    }
  }
}
