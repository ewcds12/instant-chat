part of 'messages_controller.dart';

mixin _MessageDownloads on AsyncNotifier<MessagesState> {
  MessageGateway get _gateway;
  String get _accessToken;
  Future<void> downloadFile(MessageFile file, String destinationPath) =>
      _gateway.downloadFile(
        accessToken: _accessToken,
        file: file,
        destinationPath: destinationPath,
      );

  Future<List<int>> downloadImage(MessageImage image) =>
      _gateway.downloadImage(accessToken: _accessToken, image: image);
}
