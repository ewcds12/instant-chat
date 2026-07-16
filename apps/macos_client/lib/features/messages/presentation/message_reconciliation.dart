import 'package:instant_chat/features/messages/domain/message.dart';

List<Message> reconcileMessages(
  Iterable<Message> current,
  Iterable<Message> incoming,
) {
  final byClientID = <String, Message>{};
  for (final message in [...current, ...incoming]) {
    byClientID['${message.sender.id}:${message.clientMessageId}'] = message;
  }
  final messages = byClientID.values.toList();
  messages.sort(
    (left, right) =>
        BigInt.parse(left.sequence).compareTo(BigInt.parse(right.sequence)),
  );
  return messages;
}

String latestSequence(Iterable<Message> messages) {
  var latest = BigInt.zero;
  for (final message in messages) {
    final sequence = BigInt.parse(message.sequence);
    if (sequence > latest) {
      latest = sequence;
    }
  }
  return latest.toString();
}
