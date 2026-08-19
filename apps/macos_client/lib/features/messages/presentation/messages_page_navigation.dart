part of 'messages_page.dart';

extension _MessagesPageNavigation on _MessagesPageState {
  Future<void> _loadOlderWithoutJump(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    if (!_historyScroll.hasClients) {
      return;
    }
    final previousMaxExtent = _historyScroll.position.maxScrollExtent;
    await ref.read(provider.notifier).loadOlder();
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_historyScroll.hasClients) {
        return;
      }
      final position = _historyScroll.position;
      final addedExtent = position.maxScrollExtent - previousMaxExtent;
      if (addedExtent <= 0) {
        return;
      }
      final anchoredOffset = (position.pixels + addedExtent)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      position.jumpTo(anchoredOffset);
    });
  }

  Future<void> _openMessageHistorySearch({
    required String currentUserId,
    required String accessToken,
  }) async {
    final message = await showMessageHistorySearch(
      context: context,
      participantName: widget.participantName,
      currentUserId: currentUserId,
      conversationId: widget.conversation.id,
      accessToken: accessToken,
      gateway: ref.read(messageGatewayProvider),
    );
    if (!mounted || message == null) {
      return;
    }
    ref
        .read(messageNavigationTargetProvider.notifier)
        .select(conversationId: widget.conversation.id, messageId: message.id);
  }

  void _scheduleMessageTarget(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    String messageId,
  ) {
    if (_requestedMessageId == messageId) {
      return;
    }
    _requestedMessageId = messageId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final found = await ref
          .read(provider.notifier)
          .loadThroughMessage(messageId);
      if (!mounted) {
        return;
      }
      ref.read(messageNavigationTargetProvider.notifier).clear();
      _requestedMessageId = null;
      if (!found) {
        _showSaveError(
          context.l10n.ui('The selected message could not be found.'),
        );
        return;
      }
      _showFocusedMessage(messageId);
    });
  }

  void _focusComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _composerFocus.requestFocus();
    });
  }

  void _updateNativePasteState() {
    _imageDraft.setPasteEnabled(_composerFocus.hasFocus);
  }

  void _snapHistoryToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportTracker.snapToBottom(_historyScroll, () => mounted);
    });
  }
}
