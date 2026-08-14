import 'package:instant_chat/core/network/api_response.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final PublicUser author;
  final String body;
  final DateTime createdAt;

  factory PostComment.fromJson(Map<String, Object?> json) {
    final author = json['author'];
    if (author is! Map<Object?, Object?>) {
      throw const FormatException('author must be a JSON object');
    }
    return PostComment(
      id: requiredString(json, 'id'),
      postId: requiredString(json, 'post_id'),
      author: PublicUser.fromJson(stringKeyedObject(author)),
      body: requiredString(json, 'body'),
      createdAt: requiredDateTime(json, 'created_at'),
    );
  }
}

class PostCommentPage {
  const PostCommentPage({required this.comments, required this.nextCursor});

  final List<PostComment> comments;
  final String? nextCursor;
}
