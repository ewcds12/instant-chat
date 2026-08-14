import 'package:instant_chat/features/posts/domain/public_post.dart';

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
}
