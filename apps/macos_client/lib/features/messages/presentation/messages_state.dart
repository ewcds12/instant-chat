import 'package:instant_chat/features/messages/domain/message.dart';

class FailedMessage {
  const FailedMessage.text({
    required this.clientMessageId,
    required this.body,
    this.replyToMessageId,
  }) : imagePath = null,
       filePath = null;

  const FailedMessage.image({
    required this.clientMessageId,
    required String this.imagePath,
  }) : body = '',
       replyToMessageId = null,
       filePath = null;

  const FailedMessage.file({
    required this.clientMessageId,
    required String this.filePath,
  }) : body = '',
       replyToMessageId = null,
       imagePath = null;

  final String clientMessageId;
  final String body;
  final String? imagePath;
  final String? filePath;
  final String? replyToMessageId;

  bool get isImage => imagePath != null;
  bool get isFile => filePath != null;
}

class MessagesState {
  const MessagesState({
    required this.messages,
    this.nextCursor,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.failedMessage,
    this.errorMessage,
  });

  final List<Message> messages;
  final String? nextCursor;
  final bool isLoadingOlder;
  final bool isSending;
  final FailedMessage? failedMessage;
  final String? errorMessage;

  MessagesState copyWith({
    List<Message>? messages,
    String? nextCursor,
    bool clearCursor = false,
    bool? isLoadingOlder,
    bool? isSending,
    FailedMessage? failedMessage,
    bool clearFailure = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      failedMessage: clearFailure ? null : failedMessage ?? this.failedMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
