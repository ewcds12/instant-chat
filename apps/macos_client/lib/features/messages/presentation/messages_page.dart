import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_file_actions.dart';
import 'package:instant_chat/core/platform/macos_file_picker.dart';
import 'package:instant_chat/core/platform/macos_image_picker.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';
import 'package:instant_chat/features/messages/presentation/message_header.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/message_image_preview.dart';
import 'package:instant_chat/features/messages/presentation/message_search.dart';
import 'package:instant_chat/features/messages/presentation/message_read_tracker.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';

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

  @override
  void dispose() {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = messagesControllerProvider(widget.conversation.id);
    final state = ref.watch(provider);
    final session = ref.read(authControllerProvider).requireValue.session!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageHeader(
          conversation: widget.conversation,
          onSearch: () =>
              showMessageSearch(context, state.value?.messages ?? const []),
          onRefresh: () => ref.invalidate(provider),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _LoadFailure(onRetry: () => ref.invalidate(provider)),
            data: (value) {
              _viewportTracker.schedule(value, _historyScroll, () => mounted);
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
                onLoadOlder: () => ref.read(provider.notifier).loadOlder(),
                onOpenFile: (file) => _openFile(provider, file),
                onDownloadImage: (image) => _downloadImage(provider, image),
              );
            },
          ),
        ),
        if (state.value case final value?) ...[
          if (value.errorMessage case final message?)
            _ErrorBar(message: message),
          if (value.failedMessage != null)
            _RetryBar(
              disabled: value.isSending,
              onRetry: () => ref.read(provider.notifier).retry(),
            ),
          MessageComposer(
            controller: _composer,
            focusNode: _composerFocus,
            disabled: value.isSending,
            recipientName: widget.conversation.peer.displayName,
            onSend: () => _send(provider),
            onPickImage: () => _pickAndSendImage(provider),
            onPickFile: () => _pickAndSendFile(provider),
          ),
        ],
      ],
    );
  }

  Future<void> _send(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    if (await ref.read(provider.notifier).send(_composer.text)) {
      _composer.clear();
      _focusComposer();
    }
  }

  Future<void> _pickAndSendImage(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
  ) async {
    final imagePath = await ref.read(localImagePickerProvider).pickImagePath();
    if (!mounted || imagePath == null) {
      return;
    }
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
    if (await ref.read(provider.notifier).sendFile(filePath)) {
      _focusComposer();
    }
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

  Future<void> _downloadFile(
    AsyncNotifierProvider<MessagesController, MessagesState> provider,
    LocalFileActions actions,
    MessageFile file,
  ) async {
    final path = await actions.chooseDownloadPath(file.filename);
    if (!mounted || path == null) {
      return;
    }
    final bytes = await ref.read(provider.notifier).downloadFile(file);
    await actions.writeDownloadFile(path, bytes);
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

  void _focusComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _composerFocus.requestFocus();
    });
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}

class _RetryBar extends StatelessWidget {
  const _RetryBar({required this.disabled, required this.onRetry});

  final bool disabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Expanded(child: Text('Message not sent')),
          TextButton(
            onPressed: disabled ? null : onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
