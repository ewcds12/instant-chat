import 'package:instant_chat/features/messages/domain/message.dart';

class MessagePage {
  const MessagePage({required this.messages, required this.nextCursor});

  final List<Message> messages;
  final String? nextCursor;
}
