import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageNavigationTargetProvider =
    NotifierProvider<
      MessageNavigationTargetController,
      MessageNavigationTarget?
    >(MessageNavigationTargetController.new);

class MessageNavigationTarget {
  const MessageNavigationTarget({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;
}

class MessageNavigationTargetController
    extends Notifier<MessageNavigationTarget?> {
  @override
  MessageNavigationTarget? build() => null;

  void select({required String conversationId, required String messageId}) {
    state = MessageNavigationTarget(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  void clear() => state = null;
}
