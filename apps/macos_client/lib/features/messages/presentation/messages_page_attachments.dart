part of 'messages_page.dart';

extension _MessagesPageAttachments on _MessagesPageState {
  Future<void> _send(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    _failedDroppedFile = null;
    final images = List<ClipboardImage>.of(_imageDraft.images);
    final body = _composer.text;
    final replyToMessageID = _replyingTo?.id;
    for (final image in images) {
      final sent = await ref.read(provider.notifier).sendImage(image.path);
      if (!mounted || !sent) {
        return;
      }
      _imageDraft.remove(image.path);
    }
    if (body.trim().isEmpty) {
      _focusComposer();
      return;
    }
    if (await ref
        .read(provider.notifier)
        .send(body, replyToMessageId: replyToMessageID)) {
      _composer.clear();
      _cancelReply();
      _focusComposer();
    }
  }

  void _removeDraftImage(String path) {
    _imageDraft.remove(path);
    _focusComposer();
  }

  void _showImageLimit() {
    if (mounted) {
      _showSaveError('You can attach up to 3 photos.');
    }
  }

  Future<void> _pickAndSendImage(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    final imagePath = await ref.read(localImagePickerProvider).pickImagePath();
    if (!mounted || imagePath == null) {
      return;
    }
    _failedDroppedFile = null;
    if (await ref.read(provider.notifier).sendImage(imagePath)) {
      _focusComposer();
    }
  }

  Future<void> _pickAndSendFile(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    final filePath = await ref.read(localFilePickerProvider).pickFilePath();
    if (!mounted || filePath == null) {
      return;
    }
    _failedDroppedFile = null;
    if (await ref.read(provider.notifier).sendFile(filePath)) {
      _focusComposer();
    }
  }

  Future<void> _sendDroppedFiles(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    List<MessageDroppedFile> files,
  ) async {
    for (final file in files) {
      if (file.isDirectory) {
        _showSaveError("Folders can't be sent.");
        continue;
      }
      final shouldContinue = await _sendDroppedFile(provider, file);
      if (!mounted || !shouldContinue) {
        return;
      }
    }
    _focusComposer();
  }

  Future<bool> _sendDroppedFile(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    MessageDroppedFile file,
  ) async {
    try {
      return await file.withAccess(() async {
        final byteSize = await File(file.path).length();
        final sizeError = messageDropSizeError(file.path, byteSize);
        if (sizeError != null) {
          _showSaveError(sizeError);
          return true;
        }
        final controller = ref.read(provider.notifier);
        _failedDroppedFile = null;
        final sent = messageDropPathIsImage(file.path)
            ? await controller.sendImage(file.path)
            : await controller.sendFile(file.path);
        if (!sent) {
          _failedDroppedFile = file;
          return false;
        }
        _failedDroppedFile = null;
        await file.deleteTemporaryCopy();
        return true;
      });
    } on MessageDropAccessException {
      _showSaveError('The dropped file could not be accessed.');
    } on FileSystemException {
      _showSaveError('The dropped file could not be read.');
    }
    return true;
  }

  Future<void> _retryMessage(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    final failed = ref.read(provider).value?.failedMessage;
    final droppedFile = _failedDroppedFile;
    final file =
        failed != null &&
            (failed.imagePath == droppedFile?.path ||
                failed.filePath == droppedFile?.path)
        ? droppedFile
        : null;
    if (file == null) {
      if (await ref.read(provider.notifier).retry()) {
        _cancelReply();
      }
      return;
    }
    try {
      final sent = await file.withAccess(
        () => ref.read(provider.notifier).retry(),
      );
      if (sent) {
        _failedDroppedFile = null;
        await file.deleteTemporaryCopy();
      }
    } on MessageDropAccessException {
      _showSaveError('The dropped file could not be accessed.');
    } on FileSystemException {
      _showSaveError('The dropped file could not be read.');
    }
  }
}
