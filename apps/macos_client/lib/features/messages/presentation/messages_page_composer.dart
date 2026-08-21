part of 'messages_page.dart';

extension _MessagesPageComposer on _MessagesPageState {
  Widget _buildMessageComposer(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    MessagesState value,
  ) {
    final spellCheckEnabled =
        ref.watch(spellCheckEnabledProvider).value ?? true;
    final spellCheckService = ref.watch(spellCheckPlatformProvider);
    return AnimatedBuilder(
      animation: _imageDraft,
      builder: (context, _) => MessageComposer(
        controller: _composer,
        focusNode: _composerFocus,
        disabled: value.isSending,
        recipientName: widget.participantName,
        onSend: () => _send(provider),
        onPickImage: () => _pickAndSendImage(provider),
        onPickFile: () => _pickAndSendFile(provider),
        imagePaths: _imageDraft.images
            .map((image) => image.path)
            .toList(growable: false),
        onRemoveImage: _removeDraftImage,
        onPasteImage: _imageDraft.paste,
        replyingTo: _replyingTo,
        onCancelReply: _cancelReply,
        spellCheckEnabled: spellCheckEnabled,
        spellCheckService: spellCheckService,
      ),
    );
  }
}
