import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_clipboard_image.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_file_picker.dart';
import 'package:instant_chat/core/platform/macos_image_picker.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contact_message_search.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';
import 'package:instant_chat/features/messages/presentation/message_drop_validation.dart';
import 'package:instant_chat/features/messages/presentation/message_drop_zone.dart';
import 'package:instant_chat/features/messages/presentation/message_header.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/message_image_draft.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_navigation_target.dart';
import 'package:instant_chat/features/messages/presentation/message_read_tracker.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';
import 'package:instant_chat/features/messages/presentation/message_status_bars.dart';

part 'messages_page_attachments.dart';
part 'messages_page_navigation.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({required this.conversation, super.key});

  final Conversation conversation;

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _historyScroll = ScrollController();
  final _readTracker = MessageReadTracker();
  final _viewportTracker = MessageViewportTracker();
  late final MessageImageDraft _imageDraft;
  MessageDroppedFile? _failedDroppedFile;
  Timer? _focusedMessageTimer;
  String? _requestedMessageId;
  String? _focusedMessageId;
  var _preserveHistoryPosition = false;

  @override
  void initState() {
    super.initState();
    _imageDraft = MessageImageDraft(
      ref.read(localClipboardImageProvider),
      onLimitReached: _showImageLimit,
    );
    _composerFocus.addListener(_updateNativePasteState);
  }

  @override
  void dispose() {
    _focusedMessageTimer?.cancel();
    _composerFocus.removeListener(_updateNativePasteState);
    _imageDraft.dispose();
    _composer.dispose();
    _composerFocus.dispose();
    _historyScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _readTracker.reset();
      _viewportTracker.reset();
      _imageDraft.clear();
      _failedDroppedFile = null;
      _focusedMessageTimer?.cancel();
      _focusedMessageTimer = null;
      _requestedMessageId = null;
      _focusedMessageId = null;
      _preserveHistoryPosition = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = messagesControllerProvider(widget.conversation.id);
    final state = ref.watch(provider);
    final navigationTarget = ref.watch(messageNavigationTargetProvider);
    final session = ref.read(authControllerProvider).requireValue.session!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageHeader(
          conversation: widget.conversation,
          onSearch: () => _openMessageHistorySearch(
            currentUserId: session.user.id,
            accessToken: session.accessToken,
          ),
        ),
        Expanded(
          child: MessageDropZone(
            disabled: state.value?.isSending ?? true,
            onFiles: (files) => _sendDroppedFiles(provider, files),
            child: Column(
              children: [
                Expanded(
                  child: state.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => MessageLoadFailure(
                      onRetry: () => ref.invalidate(provider),
                    ),
                    data: (value) {
                      final targetMessageId =
                          navigationTarget?.conversationId ==
                              widget.conversation.id
                          ? navigationTarget?.messageId
                          : null;
                      if (targetMessageId != null) {
                        _scheduleMessageTarget(provider, targetMessageId);
                      }
                      if (targetMessageId == null &&
                          !_preserveHistoryPosition) {
                        _viewportTracker.schedule(
                          value,
                          _historyScroll,
                          () => mounted,
                        );
                      }
                      _readTracker.schedule(
                        state: value,
                        markRead: (sequence) => ref
                            .read(conversationsControllerProvider.notifier)
                            .markRead(widget.conversation.id, sequence),
                      );
                      return MessageHistory(
                        value: value,
                        scrollController: _historyScroll,
                        accessToken: session.accessToken,
                        currentUserId: session.user.id,
                        targetMessageId: _focusedMessageId,
                        onLoadOlder: () =>
                            ref.read(provider.notifier).loadOlder(),
                        onOpenFile: (file) => _openFile(provider, file),
                        onOpenLink: _openLink,
                        onDownloadImage: (image) =>
                            _downloadImage(provider, image),
                        onRecall: (message) =>
                            ref.read(provider.notifier).recall(message),
                        onDelete: (message) =>
                            ref.read(provider.notifier).delete(message),
                      );
                    },
                  ),
                ),
                if (state.value case final value?) ...[
                  if (value.errorMessage case final message?)
                    MessageErrorBar(message: message),
                  if (value.failedMessage != null)
                    MessageRetryBar(
                      disabled: value.isSending,
                      onRetry: () => _retryMessage(provider),
                    ),
                  NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (_) {
                      _snapHistoryToBottom();
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: AnimatedBuilder(
                        animation: _imageDraft,
                        builder: (context, _) => MessageComposer(
                          controller: _composer,
                          focusNode: _composerFocus,
                          disabled: value.isSending,
                          recipientName: widget.conversation.peer.displayName,
                          onSend: () => _send(provider),
                          onPickImage: () => _pickAndSendImage(provider),
                          onPickFile: () => _pickAndSendFile(provider),
                          imagePaths: _imageDraft.images
                              .map((image) => image.path)
                              .toList(growable: false),
                          onRemoveImage: _removeDraftImage,
                          onPasteImage: _imageDraft.paste,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFile(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    MessageFile file,
  ) async {
    final actions = ref.read(localFileActionsProvider);
    final action = await actions.chooseAction(file.filename);
    if (!mounted || action == null) {
      return;
    }
    try {
      await _downloadFile(provider, actions, file);
    } catch (_) {
      if (mounted) {
        _showSaveError('File could not be saved.');
      }
    }
  }

  Future<void> _openLink(Uri link) async {
    try {
      await ref.read(localUrlLauncherProvider).open(link);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link could not be opened.')),
        );
      }
    }
  }

  Future<void> _downloadFile(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    LocalFileActions actions,
    MessageFile file,
  ) async {
    final path = await actions.chooseDownloadPath(file.filename);
    if (!mounted || path == null) {
      return;
    }
    await ref.read(provider.notifier).downloadFile(file, path);
  }

  Future<void> _downloadImage(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    MessageImage image,
  ) async {
    final actions = ref.read(localFileActionsProvider);
    try {
      final path = await actions.chooseDownloadPath(
        messageImageDownloadFilename(image),
      );
      if (!mounted || path == null) {
        return;
      }
      final bytes = await ref.read(provider.notifier).downloadImage(image);
      await actions.writeDownloadFile(path, bytes);
    } catch (_) {
      if (mounted) {
        _showSaveError('Image could not be saved.');
      }
    }
  }

  void _showSaveError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFocusedMessage(String messageId) {
    _focusedMessageTimer?.cancel();
    setState(() {
      _focusedMessageId = messageId;
      _preserveHistoryPosition = true;
    });
    _focusedMessageTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _focusedMessageId != messageId) {
        return;
      }
      _focusedMessageTimer = null;
      setState(() => _focusedMessageId = null);
    });
  }
}
