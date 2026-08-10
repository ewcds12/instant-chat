import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

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

  Future<void> report({
    required String accessToken,
    required String postId,
    required String reason,
  });

  Future<void> block({required String accessToken, required String userId});

  Future<void> unblock({required String accessToken, required String userId});

  Future<List<PublicUser>> listBlocked(String accessToken);
}
