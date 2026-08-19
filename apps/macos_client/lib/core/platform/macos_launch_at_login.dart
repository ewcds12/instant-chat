import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LaunchAtLoginStatus {
  disabled,
  enabled,
  requiresApproval,
  unsupported;

  static LaunchAtLoginStatus fromPlatform(String value) {
    return switch (value) {
      'disabled' => disabled,
      'enabled' => enabled,
      'requires_approval' => requiresApproval,
      'unsupported' => unsupported,
      _ => throw StateError('Unknown launch-at-login status: $value'),
    };
  }
}

final launchAtLoginPlatformProvider = Provider<LaunchAtLoginPlatform>(
  (ref) => const MacOSLaunchAtLoginPlatform(),
);

abstract interface class LaunchAtLoginPlatform {
  Future<LaunchAtLoginStatus> getStatus();

  Future<LaunchAtLoginStatus> setEnabled(bool enabled);
}

class MacOSLaunchAtLoginPlatform implements LaunchAtLoginPlatform {
  const MacOSLaunchAtLoginPlatform([
    this._channel = const MethodChannel('instant_chat/launch_at_login'),
  ]);

  final MethodChannel _channel;

  @override
  Future<LaunchAtLoginStatus> getStatus() async {
    final value = await _channel.invokeMethod<String>('getStatus');
    return LaunchAtLoginStatus.fromPlatform(
      value ?? (throw StateError('Launch-at-login status was empty.')),
    );
  }

  @override
  Future<LaunchAtLoginStatus> setEnabled(bool enabled) async {
    final value = await _channel.invokeMethod<String>('setEnabled', {
      'enabled': enabled,
    });
    return LaunchAtLoginStatus.fromPlatform(
      value ?? (throw StateError('Launch-at-login status was empty.')),
    );
  }
}
