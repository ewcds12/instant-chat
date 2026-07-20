part of 'messages_controller.dart';

mixin _MessageDownloads on AsyncNotifier<MessagesState> {
  MessageGateway get _gateway;
  String get _accessToken;
  Future<List<int>> downloadFile(MessageFile file) =>
      _gateway.downloadFile(accessToken: _accessToken, file: file);

  Future<List<int>> downloadImage(MessageImage image) =>
      _gateway.downloadImage(accessToken: _accessToken, image: image);
}
