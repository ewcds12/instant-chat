import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/data/dio_message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';
import 'package:instant_chat/features/messages/presentation/message_client_id.dart';
import 'package:instant_chat/features/messages/presentation/message_reconciliation.dart';
import 'package:instant_chat/features/messages/presentation/message_recovery.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/realtime/presentation/realtime_provider.dart';

part 'messages_controller_actions.dart';
part 'messages_controller_downloads.dart';
part 'messages_controller_sync.dart';

final messageGatewayProvider = Provider<MessageGateway>(
  (ref) => DioMessageGateway(ref.watch(dioProvider)),
);
final messageRecoveryIntervalProvider = Provider<Duration?>(
  (ref) => const Duration(seconds: 2),
);
final messagesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MessagesController, MessagesState, String>(MessagesController.new);

class MessagesController extends AsyncNotifier<MessagesState>
    with _MessageActions, _MessageDownloads, _MessageSync {
  MessagesController(this.conversationId);

  @override
  final String conversationId;
  final _pendingRealtime = <Message>[];
  @override
  final _pendingRecalls = <MessageRecall>[];
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<MessageRecall>? _recallSubscription;
  StreamSubscription<int>? _connectionSubscription;
  @override
  late final MessageRecovery _recovery;
  @override
  var _active = true;
  @override
  var _realtimeReady = false;

  @override
  MessageGateway get _gateway => ref.read(messageGatewayProvider);

  @override
  String get _accessToken {
    final session = ref.read(authControllerProvider).requireValue.session;
    if (session == null) {
      throw StateError('An authenticated session is required.');
    }
    return session.accessToken;
  }

  @override
  Future<MessagesState> build() async {
    _recovery = MessageRecovery(
      interval: ref.read(messageRecoveryIntervalProvider),
      synchronize: _syncNewer,
    );
    final realtime = ref.read(realtimeConnectionProvider);
    _messageSubscription = realtime.messages.listen(_receiveRealtime);
    _recallSubscription = realtime.recalls.listen(_receiveRecall);
    _connectionSubscription = realtime.connections.listen((_) {
      _recovery.queue();
      unawaited(_refreshLatest());
    });
    ref.onDispose(() {
      _active = false;
      _recovery.close();
      unawaited(_messageSubscription?.cancel());
      unawaited(_recallSubscription?.cancel());
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
      FailedMessage.text(clientMessageId: newMessageClientID(), body: trimmed),
    );
  }

  Future<bool> sendImage(String imagePath) {
    if (imagePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.image(
        clientMessageId: newMessageClientID(),
        imagePath: imagePath,
      ),
    );
  }

  Future<bool> sendFile(String filePath) {
    if (filePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.file(
        clientMessageId: newMessageClientID(),
        filePath: filePath,
      ),
    );
  }

  Future<bool> retry() async {
    final failed = state.requireValue.failedMessage;
    if (failed == null) {
      return false;
    }
    return _send(failed);
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

  Future<bool> loadThroughMessage(String messageId) async {
    while (_active && state.hasValue) {
      final current = state.requireValue;
      if (current.messages.any((message) => message.id == messageId)) {
        return true;
      }
      if (current.nextCursor == null) {
        return false;
      }
      final previousCursor = current.nextCursor;
      final previousCount = current.messages.length;
      await loadOlder();
      final latest = state.requireValue;
      if (latest.messages.any((message) => message.id == messageId)) {
        return true;
      }
      if (latest.nextCursor == previousCursor &&
          latest.messages.length == previousCount) {
        return false;
      }
    }
    return false;
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
      ref.read(conversationsControllerProvider.notifier).recordMessage(message);
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
    for (final recall in _pendingRecalls) {
      _markMessageRecalled(recall);
    }
    _pendingRecalls.clear();
    _recovery.start();
  }

  void _receiveRealtime(Message message) {
    if (message.conversationId != conversationId) {
      return;
    }
    if (!_realtimeReady || !state.hasValue) {
      _pendingRealtime.add(message);
      return;
    }
    _recovery.queueGap(
      latest: latestSequence(state.requireValue.messages),
      incoming: message.sequence,
    );
    _applyMessages([message]);
  }

  @override
  void _applyMessages(Iterable<Message> incoming) {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(messages: reconcileMessages(current.messages, incoming)),
    );
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
