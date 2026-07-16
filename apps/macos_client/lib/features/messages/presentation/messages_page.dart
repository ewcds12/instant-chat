import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/core/platform/macos_image_picker.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/messages/presentation/message_composer.dart';
import 'package:instant_chat/features/messages/presentation/message_header.dart';
import 'package:instant_chat/features/messages/presentation/message_history.dart';
import 'package:instant_chat/features/messages/presentation/message_search.dart';
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
  String? _latestMessageKey;

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
      _latestMessageKey = null;
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
              _scheduleScrollForLatestMessage(value);
              return MessageHistory(
                value: value,
                scrollController: _historyScroll,
                accessToken: session.accessToken,
                currentUserId: session.user.id,
                onLoadOlder: () => ref.read(provider.notifier).loadOlder(),
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

  void _scheduleScrollForLatestMessage(MessagesState value) {
    final messages = value.messages;
    if (messages.isEmpty) {
      _latestMessageKey = null;
      return;
    }
    final latest = messages.last;
    final latestKey = '${latest.sequence}:${latest.id}';
    if (_latestMessageKey == latestKey) {
      return;
    }
    _latestMessageKey = latestKey;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!mounted || !_historyScroll.hasClients) {
      return;
    }
    _historyScroll
        .animateTo(
          _historyScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _snapToBottomIfNeeded();
          });
        });
  }

  void _snapToBottomIfNeeded() {
    if (!mounted || !_historyScroll.hasClients) {
      return;
    }
    final position = _historyScroll.position;
    if ((position.maxScrollExtent - position.pixels).abs() > 1) {
      _historyScroll.jumpTo(position.maxScrollExtent);
    }
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
