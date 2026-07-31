import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/features/conversations/domain/conversation.dart';
import 'package:instant_chat/features/conversations/presentation/conversations_controller.dart';
import 'package:instant_chat/features/messages/domain/message.dart';
import 'package:instant_chat/features/messages/presentation/messages_controller.dart';

typedef ContactSharedContentRequest = ({
  String contactUserId,
  String accessToken,
});

final contactSharedContentProvider = FutureProvider.autoDispose
    .family<ContactSharedContent, ContactSharedContentRequest>((
      ref,
      request,
    ) async {
      final conversation = await ref.watch(
        conversationsControllerProvider.selectAsync(
          (state) => _findSharedConversation(
            state.conversations,
            request.contactUserId,
          ),
        ),
      );
      if (conversation == null) {
        return const ContactSharedContent.empty();
      }
      final page = await ref
          .read(messageGatewayProvider)
          .list(
            accessToken: request.accessToken,
            conversationId: conversation.conversationId,
          );
      return ContactSharedContent.fromMessages(page.messages);
    });

class ContactSharedContent {
  const ContactSharedContent({
    required this.images,
    required this.files,
    required this.links,
  });

  const ContactSharedContent.empty()
    : images = const [],
      files = const [],
      links = const [];

  final List<MessageImage> images;
  final List<MessageFile> files;
  final List<Uri> links;

  bool get isEmpty => images.isEmpty && files.isEmpty && links.isEmpty;

  factory ContactSharedContent.fromMessages(List<Message> messages) {
    final recent =
        messages
            .where((message) => message.recalledAt == null)
            .toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final images = <MessageImage>[];
    final files = <MessageFile>[];
    final links = <Uri>[];
    final imageIds = <String>{};
    final fileIds = <String>{};
    final linkValues = <String>{};
    for (final message in recent) {
      final image = message.image;
      if (image != null && imageIds.add(image.id)) {
        images.add(image);
      }
      final file = message.file;
      if (file != null && fileIds.add(file.id)) {
        files.add(file);
      }
      for (final link in extractWebLinks(message.body)) {
        if (linkValues.add(link.toString())) {
          links.add(link);
        }
      }
    }
    return ContactSharedContent(images: images, files: files, links: links);
  }
}

List<Uri> extractWebLinks(String text) {
  final links = <Uri>[];
  final matches = RegExp(
    r'https?://[^\s<>()]+',
    caseSensitive: false,
  ).allMatches(text);
  for (final match in matches) {
    final value = _stripTrailingPunctuation(match.group(0)!);
    final uri = Uri.tryParse(value);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      links.add(uri);
    }
  }
  return links;
}

({String conversationId, String latestSequence})? _findSharedConversation(
  List<Conversation> conversations,
  String contactUserId,
) {
  for (final conversation in conversations) {
    if (conversation.kind == 'direct' &&
        conversation.peer.id == contactUserId) {
      return (
        conversationId: conversation.id,
        latestSequence: conversation.lastMessage?.sequence ?? '',
      );
    }
  }
  return null;
}

String _stripTrailingPunctuation(String value) {
  return value.replaceFirst(RegExp(r'''[.,!?;:\]\}'"]+$'''), '');
}
