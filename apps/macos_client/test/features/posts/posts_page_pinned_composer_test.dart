import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/domain/auth_session.dart';
import 'package:instant_chat/features/auth/domain/auth_user.dart';
import 'package:instant_chat/features/auth/presentation/auth_controller.dart';
import 'package:instant_chat/features/contacts/presentation/contacts_controller.dart';
import 'package:instant_chat/features/posts/domain/post_gateway.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
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
  const _StubPostGateway(this.posts);

  final List<PublicPost> posts;

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
}
