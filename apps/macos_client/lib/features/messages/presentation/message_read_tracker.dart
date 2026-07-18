import 'package:flutter/widgets.dart';
import 'package:instant_chat/features/messages/presentation/messages_state.dart';

class MessageReadTracker {
  String? _lastReadSequence;
  String? _pendingSequence;

  void reset() {
    _lastReadSequence = null;
    _pendingSequence = null;
  }

  void schedule({
    required MessagesState state,
    required Future<bool> Function(String sequence) markRead,
  }) {
    if (state.messages.isEmpty) {
      return;
    }
    final sequence = state.messages.last.sequence;
    if (_lastReadSequence == sequence || _pendingSequence == sequence) {
      return;
    }
    _pendingSequence = sequence;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final marked = await markRead(sequence);
      if (marked) {
        _lastReadSequence = sequence;
      }
      if (_pendingSequence == sequence) {
        _pendingSequence = null;
      }
    });
  }
}

class MessageViewportTracker {
  String? _latestMessageKey;

  void reset() => _latestMessageKey = null;

  void schedule(
    MessagesState state,
    ScrollController controller,
    bool Function() isActive,
  ) {
    if (state.messages.isEmpty) {
      reset();
      return;
    }
    final latest = state.messages.last;
    final key = '${latest.sequence}:${latest.id}';
    if (_latestMessageKey == key) {
      return;
    }
    _latestMessageKey = key;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(controller, isActive),
    );
  }

  void _scrollToBottom(ScrollController controller, bool Function() isActive) {
    if (!isActive() || !controller.hasClients) {
      return;
    }
    controller
        .animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .then(
          (_) => WidgetsBinding.instance.addPostFrameCallback(
            (_) => _snapToBottom(controller, isActive),
          ),
        );
  }

  void _snapToBottom(ScrollController controller, bool Function() isActive) {
    if (!isActive() || !controller.hasClients) {
      return;
    }
    final position = controller.position;
    if ((position.maxScrollExtent - position.pixels).abs() > 1) {
      controller.jumpTo(position.maxScrollExtent);
    }
  }
}
