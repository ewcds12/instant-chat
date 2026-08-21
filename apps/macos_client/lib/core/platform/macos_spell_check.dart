import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SpellCheckPlatform implements SpellCheckService {
  Stream<bool> get enabledChanges;

  Future<bool> getEnabled();
  Future<void> setEnabled(bool enabled);
  Future<void> dispose();
}

class MethodChannelSpellCheckPlatform implements SpellCheckPlatform {
  MethodChannelSpellCheckPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('instant_chat/spell_check') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final _changes = StreamController<bool>.broadcast();

  @override
  Stream<bool> get enabledChanges => _changes.stream;

  @override
  Future<bool> getEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('getEnabled') ?? true;
    } on MissingPluginException {
      return true;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) {
    return _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async {
    final List<Object?>? results;
    try {
      results = await _channel.invokeListMethod<Object?>('check', {
        'language': locale.toLanguageTag(),
        'text': text,
      });
    } on MissingPluginException {
      return const [];
    }
    return results
        ?.map((item) {
          final value = (item as Map<Object?, Object?>);
          return SuggestionSpan(
            TextRange(
              start: value['startIndex']! as int,
              end: value['endIndex']! as int,
            ),
            (value['suggestions']! as List<Object?>).cast<String>(),
          );
        })
        .toList(growable: false);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'enabledChanged' && !_changes.isClosed) {
      _changes.add(call.arguments as bool);
    }
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _changes.close();
  }
}

final spellCheckPlatformProvider = Provider<SpellCheckPlatform>((ref) {
  final platform = MethodChannelSpellCheckPlatform();
  ref.onDispose(platform.dispose);
  return platform;
});

final spellCheckEnabledProvider =
    AsyncNotifierProvider<SpellCheckEnabledNotifier, bool>(
      SpellCheckEnabledNotifier.new,
    );

class SpellCheckEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final platform = ref.watch(spellCheckPlatformProvider);
    final subscription = platform.enabledChanges.listen((enabled) {
      state = AsyncData(enabled);
    });
    ref.onDispose(subscription.cancel);
    return platform.getEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    final previous = state.value ?? true;
    state = AsyncData(enabled);
    try {
      await ref.read(spellCheckPlatformProvider).setEnabled(enabled);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
