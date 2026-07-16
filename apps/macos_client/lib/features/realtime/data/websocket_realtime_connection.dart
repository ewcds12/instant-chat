import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/realtime/domain/realtime_connection.dart';

const _heartbeatPeriod = Duration(seconds: 20);
const _maximumReconnectDelay = Duration(seconds: 30);

class WebSocketRealtimeConnection implements RealtimeConnection {
  WebSocketRealtimeConnection({required this.uri, required this.accessToken});

  final Uri uri;
  final String accessToken;
  final _messages = StreamController<Message>.broadcast();
  final _connections = StreamController<int>.broadcast();
  final _stopSignal = Completer<void>();

  Future<void>? _runner;
  WebSocket? _socket;
  var _generation = 0;
  var _stopping = false;

  @override
  Stream<Message> get messages => _messages.stream;

  @override
  Stream<int> get connections => _connections.stream;

  @override
  void start() {
    _runner ??= _run();
  }

  @override
  Future<void> close() async {
    if (_stopping) {
      await _runner;
      return;
    }
    _stopping = true;
    _stopSignal.complete();
    await _socket?.close(WebSocketStatus.normalClosure);
    await _runner;
    await _messages.close();
    await _connections.close();
  }

  Future<void> _run() async {
    var reconnectDelay = const Duration(seconds: 1);
    while (!_stopping) {
      try {
        final socket = await WebSocket.connect(
          uri.toString(),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (_stopping) {
          await socket.close(WebSocketStatus.normalClosure);
          break;
        }
        _socket = socket;
        socket.pingInterval = _heartbeatPeriod;
        reconnectDelay = const Duration(seconds: 1);
        _connections.add(++_generation);
        await _read(socket);
      } on FormatException {
        await _socket?.close(
          WebSocketStatus.unsupportedData,
          'Invalid realtime event.',
        );
      } on IOException {
        // Network, TLS, authentication, and upgrade failures use backoff.
      } finally {
        _socket = null;
      }
      if (_stopping) {
        break;
      }
      await Future.any([
        Future<void>.delayed(reconnectDelay),
        _stopSignal.future,
      ]);
      reconnectDelay = Duration(
        seconds: (reconnectDelay.inSeconds * 2).clamp(
          1,
          _maximumReconnectDelay.inSeconds,
        ),
      );
    }
  }

  Future<void> _read(WebSocket socket) async {
    await for (final raw in socket) {
      if (_stopping) {
        return;
      }
      if (raw is! String) {
        throw const FormatException('Realtime events must be text.');
      }
      final message = decodeRealtimeMessage(raw);
      if (message != null) {
        _messages.add(message);
      }
    }
  }
}

Message? decodeRealtimeMessage(String raw) {
  final Object? decoded = jsonDecode(raw);
  final event = _object(decoded, 'event');
  _requiredString(event, 'event_id');
  _requiredDateTime(event, 'occurred_at');
  final type = _requiredString(event, 'type');
  if (type != 'message.created') {
    return null;
  }
  final version = event['version'];
  if (version != 1) {
    throw const FormatException('Unsupported message.created version.');
  }
  final payload = _object(event['payload'], 'payload');
  return Message.fromJson(_object(payload['message'], 'message'));
}

Map<String, Object?> _object(Object? value, String name) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$name must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key case final String key) {
      result[key] = entry.value;
    } else {
      throw FormatException('$name keys must be strings.');
    }
  }
  return result;
}

String _requiredString(Map<String, Object?> value, String name) {
  final field = value[name];
  if (field is! String || field.isEmpty) {
    throw FormatException('$name must be a nonempty string.');
  }
  return field;
}

DateTime _requiredDateTime(Map<String, Object?> value, String name) {
  final field = _requiredString(value, name);
  final parsed = DateTime.tryParse(field);
  if (parsed == null) {
    throw FormatException('$name must be an RFC 3339 timestamp.');
  }
  return parsed.toUtc();
}
