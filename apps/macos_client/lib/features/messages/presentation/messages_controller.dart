import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/network/api_failure.dart';
import 'package:instant_chat/core/network/dio_provider.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/messages/data/dio_message_gateway.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/domain/message_gateway.dart';

final messageGatewayProvider = Provider<MessageGateway>((ref) {
  return DioMessageGateway(ref.watch(dioProvider));
});

final messagesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MessagesController, MessagesState, String>(MessagesController.new);

class FailedMessage {
  const FailedMessage({required this.clientMessageId, required this.body});

  final String clientMessageId;
  final String body;
}

class MessagesState {
  const MessagesState({
    required this.messages,
    this.nextCursor,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.failedMessage,
    this.errorMessage,
  });

  final List<Message> messages;
  final String? nextCursor;
  final bool isLoadingOlder;
  final bool isSending;
  final FailedMessage? failedMessage;
  final String? errorMessage;

  MessagesState copyWith({
    List<Message>? messages,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingOlder,
    bool? isSending,
    FailedMessage? failedMessage,
    bool clearFailure = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      failedMessage: clearFailure ? null : failedMessage ?? this.failedMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MessagesController extends AsyncNotifier<MessagesState> {
  MessagesController(this.conversationId);

  final String conversationId;

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
    final page = await _gateway.list(
      accessToken: _accessToken,
      conversationId: conversationId,
    );
    return MessagesState(messages: page.messages, nextCursor: page.nextCursor);
  }

  Future<bool> send(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Future.value(false);
    }
    return _send(FailedMessage(clientMessageId: _newClientID(), body: trimmed));
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
      state = AsyncData(
        current.copyWith(
          messages: [...page.messages, ...current.messages],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          isLoadingOlder: false,
          clearError: true,
        ),
      );
    } on ApiFailure catch (failure) {
      _setHistoryFailure(current, failure.message);
    } on FormatException {
      _setHistoryFailure(current, 'The server returned an invalid response.');
    }
  }

  Future<bool> _send(FailedMessage pending) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(isSending: true, clearFailure: true, clearError: true),
    );
    try {
      final message = await _gateway.send(
        accessToken: _accessToken,
        conversationId: conversationId,
        clientMessageId: pending.clientMessageId,
        body: pending.body,
      );
      final messages =
          current.messages.any(
            (item) => item.clientMessageId == message.clientMessageId,
          )
          ? current.messages
          : [...current.messages, message];
      state = AsyncData(
        current.copyWith(
          messages: messages,
          isSending: false,
          clearFailure: true,
          clearError: true,
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      _setSendFailure(current, pending, failure.message);
    } on FormatException {
      _setSendFailure(
        current,
        pending,
        'The server returned an invalid response.',
      );
    }
    return false;
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
