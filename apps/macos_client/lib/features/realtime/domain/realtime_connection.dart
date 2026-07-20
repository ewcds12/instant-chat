import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

abstract interface class RealtimeConnection {
  Stream<Message> get messages;

  Stream<MessageRecall> get recalls;

  Stream<PublicUser> get profiles;

  Stream<int> get connections;

  void start();

  Future<void> close();
}
