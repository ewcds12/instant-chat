import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_language.dart';

abstract interface class AppLanguagePlatform {
  Stream<AppLanguage> get languageChanges;

  Future<AppLanguage> getLanguage();
  Future<void> setLanguage(AppLanguage language);
  Future<void> dispose();
}

class MethodChannelAppLanguagePlatform implements AppLanguagePlatform {
  MethodChannelAppLanguagePlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('instant_chat/app_language') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final _changes = StreamController<AppLanguage>.broadcast();

  @override
  Stream<AppLanguage> get languageChanges => _changes.stream;

  @override
  Future<AppLanguage> getLanguage() async {
    final code = await _channel.invokeMethod<String>('getLanguage');
    return AppLanguage.fromPlatformCode(code);
  }

  @override
  Future<void> setLanguage(AppLanguage language) {
    return _channel.invokeMethod<void>('setLanguage', {
      'code': language.platformCode,
    });
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'languageChanged' || _changes.isClosed) {
      return;
    }
    _changes.add(AppLanguage.fromPlatformCode(call.arguments as String?));
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _changes.close();
  }
}

final appLanguagePlatformProvider = Provider<AppLanguagePlatform>((ref) {
  final platform = MethodChannelAppLanguagePlatform();
  ref.onDispose(platform.dispose);
  return platform;
});

final appLanguageProvider =
    AsyncNotifierProvider<AppLanguageNotifier, AppLanguage>(
      AppLanguageNotifier.new,
    );

class AppLanguageNotifier extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() async {
    final platform = ref.watch(appLanguagePlatformProvider);
    final subscription = platform.languageChanges.listen((language) {
      state = AsyncData(language);
    });
    ref.onDispose(subscription.cancel);
    return platform.getLanguage();
  }

  Future<void> setLanguage(AppLanguage language) async {
    final previous = state.value ?? AppLanguage.english;
    state = AsyncData(language);
    try {
      await ref.read(appLanguagePlatformProvider).setLanguage(language);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
