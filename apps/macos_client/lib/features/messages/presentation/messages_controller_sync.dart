part of 'messages_controller.dart';

mixin _MessageSync on AsyncNotifier<MessagesState> {
  MessageGateway get _gateway;
  String get _accessToken;
  String get conversationId;
  bool get _active;
  MessageRecovery get _recovery;
  void _applyMessages(Iterable<Message> incoming);

  Future<void> _syncNewer() async {
    if (!_recovery.begin()) {
      return;
    }
    var after = _recovery.consumeAfter(
      latestSequence(state.requireValue.messages),
    );
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
      // The fallback synchronization retries transient recovery failures.
    } on FormatException {
      // A malformed recovery page is retried by the fallback synchronization.
    } finally {
      _recovery.finish();
    }
  }

  Future<void> _refreshLatest() async {
    if (!_active || !state.hasValue) {
      return;
    }
    try {
      final page = await _gateway.list(
        accessToken: _accessToken,
        conversationId: conversationId,
        limit: 100,
      );
      if (!_active || !state.hasValue) {
        return;
      }
      final current = state.requireValue;
      final firstSequence = page.messages.firstOrNull?.sequence;
      final older = firstSequence == null
          ? const <Message>[]
          : current.messages
                .where(
                  (message) =>
                      BigInt.parse(message.sequence) <
                      BigInt.parse(firstSequence),
                )
                .toList(growable: false);
      state = AsyncData(
        current.copyWith(
          messages: reconcileMessages(older, page.messages),
          clearError: true,
        ),
      );
    } on ApiFailure {
      // The next connection or recovery cycle retries the refresh.
    } on FormatException {
      // The next connection or recovery cycle retries the refresh.
    }
  }
}
