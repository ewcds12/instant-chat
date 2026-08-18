import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_comments_controller.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test(
    'inserts replies under their root and removes the whole thread',
    () async {
      final gateway = _Gateway();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_AuthController.new),
          postGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final provider = postCommentsControllerProvider('41');
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      final controller = container.read(provider.notifier);

      expect(await controller.create('Root'), isTrue);
      expect(
        await controller.create('Reply', parentCommentId: 'comment-1'),
        isTrue,
      );

      final comments = container.read(provider).requireValue.comments;
      expect(comments.map((comment) => comment.id), ['comment-1', 'comment-2']);
      expect(comments.last.parentCommentId, 'comment-1');

      expect(await controller.delete('comment-1'), 2);
      expect(container.read(provider).requireValue.comments, isEmpty);
    },
  );
}

class _AuthController extends AuthController {
  @override
  Future<AuthState> build() async => AuthState(session: _session);
}

class _Gateway implements PostGateway {
  var _sequence = 0;

  @override
  Future<PostCommentPage> listComments({
    required String accessToken,
    required String postId,
    String? before,
    int limit = 30,
  }) async => const PostCommentPage(comments: [], nextCursor: null);

  @override
  Future<PostComment> createComment({
    required String accessToken,
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    _sequence++;
    return PostComment(
      id: 'comment-$_sequence',
      postId: postId,
      parentCommentId: parentCommentId,
      author: _author,
      body: body,
      createdAt: DateTime.utc(2026, 8, 15, 8, _sequence),
    );
  }

  @override
  Future<void> deleteComment({
    required String accessToken,
    required String postId,
    required String commentId,
  }) async {}

  @override
  Future<PublicPostPage> list({
    required String accessToken,
    String? before,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<PublicPost> create({
    required String accessToken,
    required String body,
    required List<String> imagePaths,
  }) => throw UnimplementedError();

  @override
  Future<void> delete({required String accessToken, required String postId}) =>
      throw UnimplementedError();

  @override
  Future<List<int>> downloadImage({
    required String accessToken,
    required PublicPostImage image,
  }) => throw UnimplementedError();

  @override
  Future<void> report({
    required String accessToken,
    required String postId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<PostLikeState> like({
    required String accessToken,
    required String postId,
  }) => throw UnimplementedError();

  @override
  Future<PostLikeState> unlike({
    required String accessToken,
    required String postId,
  }) => throw UnimplementedError();
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 8, 15),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 8, 15, 12),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 9, 15),
);

final _author = PublicUser(
  id: '7',
  username: 'operator',
  displayName: 'Operator',
  createdAt: DateTime.utc(2026, 8, 15),
);
