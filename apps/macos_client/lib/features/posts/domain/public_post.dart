import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class PublicPostImage {
  const PublicPostImage({
    required this.id,
    required this.position,
    required this.contentType,
    required this.byteSize,
    required this.url,
  });

  final String id;
  final int position;
  final String contentType;
  final int byteSize;
  final String url;

  factory PublicPostImage.fromJson(Map<String, Object?> json) {
    final position = json['position'];
    final byteSize = json['byte_size'];
    if (position is! int || byteSize is! int) {
      throw const FormatException('Post image metadata is invalid.');
    }
    return PublicPostImage(
      id: requiredString(json, 'id'),
      position: position,
      contentType: requiredString(json, 'content_type'),
      byteSize: byteSize,
      url: requiredString(json, 'url'),
    );
  }
}

class PublicPost {
  const PublicPost({
    required this.id,
    required this.author,
    required this.body,
    required this.images,
    required this.createdAt,
  });

  final String id;
  final PublicUser author;
  final String body;
  final List<PublicPostImage> images;
  final DateTime createdAt;

  factory PublicPost.fromJson(Map<String, Object?> json) {
    final author = json['author'];
    if (author is! Map<Object?, Object?>) {
      throw const FormatException('author must be a JSON object');
    }
    return PublicPost(
      id: requiredString(json, 'id'),
      author: PublicUser.fromJson(stringKeyedObject(author)),
      body: json['body'] is String ? json['body']! as String : '',
      images: requiredList(json, 'images')
          .map((item) {
            if (item is! Map<Object?, Object?>) {
              throw const FormatException('images must contain objects');
            }
            return PublicPostImage.fromJson(stringKeyedObject(item));
          })
          .toList(growable: false),
      createdAt: requiredDateTime(json, 'created_at'),
    );
  }
}

class PublicPostPage {
  const PublicPostPage({required this.posts, required this.nextCursor});

  final List<PublicPost> posts;
  final String? nextCursor;
}
