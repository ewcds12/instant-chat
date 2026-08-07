import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appWindowControllerProvider = Provider<AppWindowController>(
  (ref) => const MacOSAppWindowController(),
);

enum AppWindowMode {
  authentication('authentication'),
  main('main');

  const AppWindowMode(this.value);

  final String value;
}

abstract interface class AppWindowController {
  Future<void> setMode(AppWindowMode mode);
}

class MacOSAppWindowController implements AppWindowController {
  const MacOSAppWindowController([
    this._channel = const MethodChannel('instant_chat/window'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> setMode(AppWindowMode mode) async {
    try {
      await _channel.invokeMethod<void>('setMode', mode.value);
    } on MissingPluginException {
      // Widget tests do not attach the native macOS runner.
    }
  }
}
