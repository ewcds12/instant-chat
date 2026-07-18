import 'dart:async';

class MessageRecovery {
  MessageRecovery({required this.interval, required this.synchronize});

  final Duration? interval;
  final Future<void> Function() synchronize;

  Timer? _timer;
  String? _after;
  var _active = true;
  var _started = false;
  var _syncing = false;
  var _pending = false;

  void start() {
    if (!_active || _started) {
      return;
    }
    _started = true;
    if (interval != null) {
      _timer = Timer.periodic(interval!, (_) => queue());
    }
    queue();
  }

  void queue({String? after}) {
    if (!_active) {
      return;
    }
    if (after != null &&
        (_after == null || BigInt.parse(after) < BigInt.parse(_after!))) {
      _after = after;
    }
    _pending = true;
    if (_started && !_syncing) {
      unawaited(synchronize());
    }
  }

  void queueGap({required String latest, required String incoming}) {
    if (BigInt.parse(incoming) > BigInt.parse(latest) + BigInt.one) {
      queue(after: latest);
    }
  }

  bool begin() {
    if (!_active || !_started || _syncing || !_pending) {
      return false;
    }
    _syncing = true;
    _pending = false;
    return true;
  }

  String consumeAfter(String fallback) {
    final after = _after ?? fallback;
    _after = null;
    return after;
  }

  void finish() {
    _syncing = false;
    if (_active && _started && _pending) {
      unawaited(synchronize());
    }
  }

  void close() {
    _active = false;
    _timer?.cancel();
  }
}
