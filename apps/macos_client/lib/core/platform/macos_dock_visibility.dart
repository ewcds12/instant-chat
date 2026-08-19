import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dockVisibilityPlatformProvider = Provider<DockVisibilityPlatform>(
  (ref) => const MacOSDockVisibilityPlatform(),
);

abstract interface class DockVisibilityPlatform {
  Future<bool> getKeepAppInDock();

  Future<void> setKeepAppInDock(bool enabled);
}

class MacOSDockVisibilityPlatform implements DockVisibilityPlatform {
  const MacOSDockVisibilityPlatform([
    this._channel = const MethodChannel('instant_chat/dock_visibility'),
  ]);

  final MethodChannel _channel;

  @override
  Future<bool> getKeepAppInDock() async {
    final value = await _channel.invokeMethod<bool>('getKeepAppInDock');
    return value ?? true;
  }

  @override
  Future<void> setKeepAppInDock(bool enabled) {
    return _channel.invokeMethod<void>('setKeepAppInDock', {
      'enabled': enabled,
    });
  }
}
