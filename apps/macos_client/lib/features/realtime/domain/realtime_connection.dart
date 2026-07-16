import 'package:instant_chat/features/messages/domain/message.dart';

abstract interface class RealtimeConnection {
  Stream<Message> get messages;

  Stream<int> get connections;

  void start();

  Future<void> close();
}
