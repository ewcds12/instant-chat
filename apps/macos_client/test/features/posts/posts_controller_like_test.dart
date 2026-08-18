import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('persists like and unlike states returned by the gateway', () async {
    final gateway = _Gateway();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_AuthController.new),
        postGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    final subscription = container.listen(postsControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(postsControllerProvider.future);
    final controller = container.read(postsControllerProvider.notifier);

    expect(await controller.toggleLike('41'), isTrue);
    var post = container
        .read(postsControllerProvider)
        .requireValue
        .posts
        .single;
    expect(gateway.lastAction, 'like');
    expect(post.likeCount, 3);
    expect(post.likedByMe, isTrue);

    expect(await controller.toggleLike('41'), isTrue);
    post = container.read(postsControllerProvider).requireValue.posts.single;
    expect(gateway.lastAction, 'unlike');
    expect(post.likeCount, 2);
    expect(post.likedByMe, isFalse);
  });
}

class _AuthController extends AuthController {
  @override
  Future<AuthState> build() async => AuthState(session: _session);
}

class _Gateway implements PostGateway {
  String? lastAction;

  @override
  Future<PublicPostPage> list({
    required String accessToken,
    String? before,
    int limit = 20,
  }) async => PublicPostPage(posts: [_post], nextCursor: null);

  @override
  Future<PostLikeState> like({
    required String accessToken,
    required String postId,
  }) async {
    lastAction = 'like';
    return const PostLikeState(likeCount: 3, likedByMe: true);
  }

  @override
  Future<PostLikeState> unlike({
    required String accessToken,
    required String postId,
  }) async {
    lastAction = 'unlike';
    return const PostLikeState(likeCount: 2, likedByMe: false);
  }

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
  Future<PostCommentPage> listComments({
    required String accessToken,
    required String postId,
    String? before,
    int limit = 30,
  }) => throw UnimplementedError();

  @override
  Future<PostComment> createComment({
    required String accessToken,
    required String postId,
    required String body,
    String? parentCommentId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteComment({
    required String accessToken,
    required String postId,
    required String commentId,
  }) => throw UnimplementedError();
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 8, 18),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 8, 18, 12),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 9, 18),
);

final _post = PublicPost(
  id: '41',
  author: PublicUser(
    id: '8',
    username: 'author',
    displayName: 'Author',
    createdAt: DateTime.utc(2026, 8, 18),
  ),
  body: 'Persistent likes',
  images: const [],
  likeCount: 2,
  createdAt: DateTime.utc(2026, 8, 18, 9),
);
