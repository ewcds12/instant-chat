import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CloseWindowBehavior {
  keepRunning('keep_running'),
  quitApplication('quit_application');

  const CloseWindowBehavior(this.platformValue);

  final String platformValue;

  static CloseWindowBehavior fromPlatformValue(String? value) {
    return CloseWindowBehavior.values.firstWhere(
      (behavior) => behavior.platformValue == value,
      orElse: () => CloseWindowBehavior.keepRunning,
    );
  }
}

final closeWindowBehaviorPlatformProvider =
    Provider<CloseWindowBehaviorPlatform>(
      (ref) => const MacOSCloseWindowBehaviorPlatform(),
    );

abstract interface class CloseWindowBehaviorPlatform {
  Future<CloseWindowBehavior> getBehavior();

  Future<void> setBehavior(CloseWindowBehavior behavior);
}

class MacOSCloseWindowBehaviorPlatform implements CloseWindowBehaviorPlatform {
  const MacOSCloseWindowBehaviorPlatform([
    this._channel = const MethodChannel('instant_chat/close_window_behavior'),
  ]);

  final MethodChannel _channel;

  @override
  Future<CloseWindowBehavior> getBehavior() async {
    final value = await _channel.invokeMethod<String>('getBehavior');
    return CloseWindowBehavior.fromPlatformValue(value);
  }

  @override
  Future<void> setBehavior(CloseWindowBehavior behavior) {
    return _channel.invokeMethod<void>('setBehavior', {
      'behavior': behavior.platformValue,
    });
  }
}
