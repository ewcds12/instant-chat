import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/messages/data/dio_message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/presentation/message_reconciliation.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

final messageGatewayProvider = Provider<MessageGateway>((ref) {
  return DioMessageGateway(ref.watch(dioProvider));
});

final messagesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MessagesController, MessagesState, String>(MessagesController.new);

class MessagesController extends AsyncNotifier<MessagesState> {
  MessagesController(this.conversationId);

  final String conversationId;
  final _pendingRealtime = <Message>[];
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<int>? _connectionSubscription;
  var _active = true;
  var _realtimeReady = false;
  var _syncing = false;
  var _pendingSync = false;

  MessageGateway get _gateway => ref.read(messageGatewayProvider);

  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<MessagesState> build() async {
    final realtime = ref.read(realtimeConnectionProvider);
    _messageSubscription = realtime.messages.listen(_receiveRealtime);
    _connectionSubscription = realtime.connections.listen((_) {
      _pendingSync = true;
      _startPendingSync();
    });
    ref.onDispose(() {
      _active = false;
      unawaited(_messageSubscription?.cancel());
      unawaited(_connectionSubscription?.cancel());
    });
    final page = await _gateway.list(
      accessToken: _accessToken,
      conversationId: conversationId,
    );
    final messages = reconcileMessages(page.messages, _pendingRealtime);
    _pendingRealtime.clear();
    Timer.run(_activateRealtime);
    return MessagesState(messages: messages, nextCursor: page.nextCursor);
  }

  Future<bool> send(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.text(clientMessageId: _newClientID(), body: trimmed),
    );
  }

  Future<bool> sendImage(String imagePath) {
    if (imagePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.image(
        clientMessageId: _newClientID(),
        imagePath: imagePath,
      ),
    );
  }

  Future<bool> sendFile(String filePath) {
    if (filePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.file(clientMessageId: _newClientID(), filePath: filePath),
    );
  }

  Future<bool> retry() async {
    final failed = state.requireValue.failedMessage;
    if (failed == null) {
      return false;
    }
    return _send(failed);
  }

  Future<List<int>> downloadFile(MessageFile file) {
    return _gateway.downloadFile(accessToken: _accessToken, file: file);
  }

  Future<void> loadOlder() async {
    final current = state.requireValue;
    if (current.nextCursor == null ||
        current.isLoadingOlder ||
        current.isSending) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingOlder: true, clearError: true));
    try {
      final page = await _gateway.list(
        accessToken: _accessToken,
        conversationId: conversationId,
        before: current.nextCursor,
      );
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          messages: reconcileMessages(latest.messages, page.messages),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingOlder: false,
          clearError: true,
        ),
      );
    } on ApiFailure catch (failure) {
      _setHistoryFailure(state.requireValue, failure.message);
    } on FormatException {
      _setHistoryFailure(
        state.requireValue,
        'The server returned an invalid response.',
      );
    }
  }

  Future<bool> _send(FailedMessage pending) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(isSending: true, clearFailure: true, clearError: true),
    );
    try {
      final message = await _sendPendingMessage(pending);
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          messages: reconcileMessages(latest.messages, [message]),
          isSending: false,
          clearFailure: true,
          clearError: true,
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      _setSendFailure(state.requireValue, pending, failure.message);
    } on FormatException {
      _setSendFailure(
        state.requireValue,
        pending,
        'The server returned an invalid response.',
      );
    }
    return false;
  }

  Future<Message> _sendPendingMessage(FailedMessage pending) {
    final imagePath = pending.imagePath;
    if (imagePath != null) {
      return _gateway.sendImage(
        accessToken: _accessToken,
        conversationId: conversationId,
        clientMessageId: pending.clientMessageId,
        imagePath: imagePath,
      );
    }
    final filePath = pending.filePath;
    if (filePath != null) {
      return _gateway.sendFile(
        accessToken: _accessToken,
        conversationId: conversationId,
        clientMessageId: pending.clientMessageId,
        filePath: filePath,
      );
    }
    return _gateway.send(
      accessToken: _accessToken,
      conversationId: conversationId,
      clientMessageId: pending.clientMessageId,
      body: pending.body,
    );
  }

  void _activateRealtime() {
    if (!_active || !state.hasValue) {
      return;
    }
    _realtimeReady = true;
    if (_pendingRealtime.isNotEmpty) {
      _applyMessages(List.of(_pendingRealtime));
      _pendingRealtime.clear();
    }
    _startPendingSync();
  }

  void _receiveRealtime(Message message) {
    if (message.conversationId != conversationId) {
      return;
    }
    if (!_realtimeReady || !state.hasValue) {
      _pendingRealtime.add(message);
      return;
    }
    _applyMessages([message]);
  }

  void _applyMessages(Iterable<Message> incoming) {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(messages: reconcileMessages(current.messages, incoming)),
    );
  }

  void _startPendingSync() {
    if (!_active || !_realtimeReady || !_pendingSync || _syncing) {
      return;
    }
    unawaited(_syncNewer());
  }

  Future<void> _syncNewer() async {
    _syncing = true;
    _pendingSync = false;
    var after = latestSequence(state.requireValue.messages);
    try {
      while (_active) {
        final page = await _gateway.list(
          accessToken: _accessToken,
          conversationId: conversationId,
          after: after,
          limit: 100,
        );
        if (!_active) {
          return;
        }
        _applyMessages(page.messages);
        final next = page.nextCursor;
        if (next == null) {
          return;
        }
        after = next;
      }
    } on ApiFailure {
      // The next successful connection retries sequence-based recovery.
    } on FormatException {
      // A malformed recovery page is retried after the next connection.
    } finally {
      _syncing = false;
      _startPendingSync();
    }
  }

  void _setSendFailure(
    MessagesState current,
    FailedMessage pending,
    String message,
  ) {
    state = AsyncData(
      current.copyWith(
        isSending: false,
        failedMessage: pending,
        errorMessage: message,
      ),
    );
  }

  void _setHistoryFailure(MessagesState current, String message) {
    state = AsyncData(
      current.copyWith(isLoadingOlder: false, errorMessage: message),
    );
  }
}

String _newClientID() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
