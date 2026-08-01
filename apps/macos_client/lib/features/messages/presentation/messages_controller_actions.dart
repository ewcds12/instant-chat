part of 'messages_controller.dart';

mixin _MessageActions on AsyncNotifier<MessagesState> {
  MessageGateway get _gateway;
  String get _accessToken;
  String get conversationId;
  bool get _realtimeReady;
  List<MessageRecall> get _pendingRecalls;
  Future<bool> recall(Message message) async {
    try {
      await _gateway.recall(
        accessToken: _accessToken,
        conversationId: conversationId,
        messageId: message.id,
      );
      if (!ref.mounted) {
        return false;
      }
      _markMessageRecalled(
        MessageRecall(
          conversationId: conversationId,
          messageId: message.id,
          recalledAt: DateTime.now().toUtc(),
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      _setActionFailure(failure.message);
    } on FormatException {
      _setActionFailure('The server returned an invalid response.');
    }
    return false;
  }

  Future<bool> delete(Message message) => _removeFromServer(
    message,
    () => _gateway.delete(
      accessToken: _accessToken,
      conversationId: conversationId,
      messageId: message.id,
    ),
  );

  void _receiveRecall(MessageRecall recall) {
    if (recall.conversationId != conversationId) {
      return;
    }
    if (!_realtimeReady || !state.hasValue) {
      _pendingRecalls.add(recall);
      return;
    }
    _markMessageRecalled(recall);
  }

  Future<bool> _removeFromServer(
    Message message,
    Future<void> Function() request,
  ) async {
    try {
      await request();
      if (!ref.mounted) {
        return false;
      }
      _removeMessage(message.id);
      return true;
    } on ApiFailure catch (failure) {
      _setActionFailure(failure.message);
    } on FormatException {
      _setActionFailure('The server returned an invalid response.');
    }
    return false;
  }

  void _removeMessage(String messageId) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    final messages = current.messages
        .where((message) => message.id != messageId)
        .toList(growable: false);
    if (messages.length == current.messages.length) {
      return;
    }
    state = AsyncData(current.copyWith(messages: messages, clearError: true));
    ref
        .read(conversationsControllerProvider.notifier)
        .refreshAfterMessageRemoval();
  }

  void _markMessageRecalled(MessageRecall recall) {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }
    var found = false;
    final messages = current.messages
        .map((message) {
          var updated = message.withRecalledReply(
            recall.messageId,
            recall.recalledAt,
          );
          if (message.id == recall.messageId) {
            found = true;
            updated = message.recalled(recall.recalledAt);
          } else if (!identical(updated, message)) {
            found = true;
          }
          return updated;
        })
        .toList(growable: false);
    if (!found) {
      return;
    }
    state = AsyncData(current.copyWith(messages: messages, clearError: true));
    ref
        .read(conversationsControllerProvider.notifier)
        .refreshAfterMessageRemoval();
  }

  void _setActionFailure(String message) {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(errorMessage: message));
    }
  }
}
