import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_composer.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_row.dart';
import 'package:instant_chat/features/posts/presentation/posts_controller.dart';
import 'package:instant_chat/features/posts/presentation/posts_page.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('scrolls the composer away without showing a scrollbar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(_StubContactsController.new),
          postGatewayProvider.overrideWithValue(_StubPostGateway(_posts)),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: const Scaffold(body: PostsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final composer = find.byKey(const Key('explore-composer-flow'));
    final feed = find.byKey(const PageStorageKey('explore-feed'));
    final feedController = tester.widget<ListView>(feed).controller!;
    expect(composer, findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);

    await tester.drag(feed, const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(composer, findsNothing);
    expect(feedController.offset, greaterThan(0));
  });

  testWidgets('opens post comments and submits from the compact composer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _StubAuthController(AuthState(session: _session)),
          ),
          contactsControllerProvider.overrideWith(_StubContactsController.new),
          postGatewayProvider.overrideWithValue(_StubPostGateway(_posts)),
        ],
        child: MaterialApp(
          theme: RetroTheme.data,
          home: const Scaffold(body: PostsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Comments').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('post-detail-back')), findsOneWidget);
    expect(find.byKey(const Key('post-comment-field')), findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);

    await tester.enterText(
      find.byKey(const Key('post-comment-field')),
      'Nice photo',
    );
    await tester.tap(find.byKey(const Key('post-comment-send')));
    await tester.pumpAndSettle();

    expect(find.text('Nice photo'), findsOneWidget);
  });

  testWidgets('renders a nested reply and compact reply action', (
    tester,
  ) async {
    final comment = PostComment(
      id: 'comment-1',
      postId: 'post-1',
      parentCommentId: null,
      author: _author,
      body: 'Nice photo',
      createdAt: DateTime.utc(2026, 8, 14, 11),
    );
    final reply = PostComment(
      id: 'comment-2',
      postId: 'post-1',
      parentCommentId: 'comment-1',
      author: _author,
      body: 'Thanks',
      createdAt: DateTime.utc(2026, 8, 14, 12),
    );
    PostComment? replyTarget;
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: PostCommentRow(
            comment: comment,
            replies: [reply],
            accessToken: 'access-token',
            currentUserId: '8',
            onReply: (comment) => replyTarget = comment,
            onDelete: (_) {},
          ),
        ),
      ),
    );

    final dividerFinder = find.byKey(
      const Key('post-comment-divider-comment-1'),
    );
    expect(dividerFinder, findsOneWidget);
    expect(tester.widget<Divider>(dividerFinder).thickness, 1);
    expect(find.byKey(const Key('post-comment-body-comment-2')), findsNothing);

    await tester.tap(
      find.byKey(const Key('post-comment-show-replies-comment-1')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('post-comment-body-comment-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('post-comment-collapse-replies-comment-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('post-comment-reply-comment-2')));
    expect(replyTarget?.id, 'comment-2');
  });

  testWidgets('composer sends a reply to the root comment', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final root = PostComment(
      id: 'comment-1',
      postId: 'post-1',
      parentCommentId: null,
      author: _author,
      body: 'Nice photo',
      createdAt: DateTime.utc(2026, 8, 14, 11),
    );
    final reply = PostComment(
      id: 'comment-2',
      postId: 'post-1',
      parentCommentId: root.id,
      author: _author,
      body: 'Thanks',
      createdAt: DateTime.utc(2026, 8, 14, 12),
    );
    String? submittedParent;
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: PostCommentComposer(
            user: _session.user,
            accessToken: _session.accessToken,
            disabled: false,
            replyingTo: reply,
            focusNode: focusNode,
            onCancelReply: () {},
            onSend: (body, parentCommentId) async {
              submittedParent = parentCommentId;
              return true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Replying to Operator'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('post-comment-field')), 'Yes');
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('post-comment-send')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('post-comment-send')));
    await tester.pumpAndSettle();

    expect(submittedParent, root.id);
  });
}

final _session = AuthSession(
  user: AuthUser(
    id: '7',
    username: 'operator',
    displayName: 'Operator',
    createdAt: DateTime.utc(2026, 8, 14),
  ),
  accessToken: 'access-token',
  accessExpiresAt: DateTime.utc(2026, 8, 14, 12),
  refreshToken: 'refresh-token',
  refreshExpiresAt: DateTime.utc(2026, 9, 14),
);

final _author = PublicUser(
  id: '7',
  username: 'operator',
  displayName: 'Operator',
  createdAt: DateTime.utc(2026, 8, 14),
);

final _posts = List.generate(
  14,
  (index) => PublicPost(
    id: '${index + 1}',
    author: _author,
    body: 'Post body $index',
    images: const [],
    createdAt: DateTime.utc(2026, 8, 14, 10, index),
  ),
);

class _StubAuthController extends AuthController {
  _StubAuthController(this.authState);

  final AuthState authState;

  @override
  Future<AuthState> build() async => authState;
}

class _StubContactsController extends ContactsController {
  @override
  Future<ContactsState> build() async =>
      const ContactsState(contacts: [], incoming: [], outgoing: []);
}

class _StubPostGateway implements PostGateway {
  _StubPostGateway(this.posts);

  final List<PublicPost> posts;
  var _commentSequence = 0;

  @override
  Future<PublicPostPage> list({
    required String accessToken,
    String? before,
    int limit = 20,
  }) async => PublicPostPage(posts: posts, nextCursor: null);

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
    _commentSequence++;
    return PostComment(
      id: 'comment-$_commentSequence',
      postId: postId,
      parentCommentId: parentCommentId,
      author: _author,
      body: body,
      createdAt: DateTime.utc(2026, 8, 14, 11),
    );
  }

  @override
  Future<void> deleteComment({
    required String accessToken,
    required String postId,
    required String commentId,
  }) => throw UnimplementedError();
}
