part of 'messages_controller.dart';

mixin _MessageSend on AsyncNotifier<MessagesState> {
  Future<bool> _send(FailedMessage pending);

  Future<bool> send(String body, {String? replyToMessageId}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.text(
        clientMessageId: newMessageClientID(),
        body: trimmed,
        replyToMessageId: replyToMessageId,
      ),
    );
  }

  Future<bool> sendImage(String imagePath) {
    if (imagePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.image(
        clientMessageId: newMessageClientID(),
        imagePath: imagePath,
      ),
    );
  }

  Future<bool> sendFile(String filePath) {
    if (filePath.trim().isEmpty) {
      return Future.value(false);
    }
    return _send(
      FailedMessage.file(
        clientMessageId: newMessageClientID(),
        filePath: filePath,
      ),
    );
  }

  Future<bool> retry() async {
    final failed = state.requireValue.failedMessage;
    if (failed == null) {
      return false;
    }
    return _send(failed);
  }
}
