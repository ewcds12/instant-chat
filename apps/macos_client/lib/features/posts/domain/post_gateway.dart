import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';

abstract interface class PostGateway {
  Future<PublicPostPage> list({
    required String accessToken,
    String? before,
    int limit = 20,
  });

  Future<PublicPost> create({
    required String accessToken,
    required String body,
    required List<String> imagePaths,
  });

  Future<void> delete({required String accessToken, required String postId});

  Future<List<int>> downloadImage({
    required String accessToken,
    required PublicPostImage image,
  });

  Future<void> report({
    required String accessToken,
    required String postId,
    required String reason,
  });

  Future<PostLikeState> like({
    required String accessToken,
    required String postId,
  });

  Future<PostLikeState> unlike({
    required String accessToken,
    required String postId,
  });

  Future<PostCommentPage> listComments({
    required String accessToken,
    required String postId,
    String? before,
    int limit = 30,
  });

  Future<PostComment> createComment({
    required String accessToken,
    required String postId,
    required String body,
    String? parentCommentId,
  });

  Future<void> deleteComment({
    required String accessToken,
    required String postId,
    required String commentId,
  });
}
