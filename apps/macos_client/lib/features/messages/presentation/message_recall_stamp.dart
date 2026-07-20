import 'package:flutter/material.dart';
import 'package:instant_chat/features/messages/domain/message.dart';

class MessageRecallStamp extends StatelessWidget {
  const MessageRecallStamp({
    required this.message,
    required this.isMine,
    super.key,
  });

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final label = isMine
        ? 'You recalled a message'
        : '${message.sender.displayName} recalled a message';
    return Center(
      child: Text(
        key: Key('message-recall-${message.id}'),
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
