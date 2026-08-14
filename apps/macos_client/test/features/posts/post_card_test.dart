import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/post_card.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('renders a compact post and owner delete action', (tester) async {
    PostAction? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 660,
              child: PostCard(
                post: _post,
                accessToken: 'token',
                isOwnPost: true,
                onAction: (value) => selected = value,
                onDownloadImage: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello everyone'), findsOneWidget);
    expect(find.text('Retro User'), findsOneWidget);
    final postRight = tester.getRect(find.byType(PostCard)).right;
    final menuRight = tester.getRect(find.byTooltip('Post actions')).right;
    expect(
      menuRight,
      moreOrLessEquals(
        postRight - RetroMetrics.explorePostHorizontalInset,
        epsilon: 0.1,
      ),
    );
    await tester.tap(find.byTooltip('Like'));
    await tester.pump();
    expect(find.byTooltip('Unlike'), findsOneWidget);
    await tester.tap(find.byTooltip('Bookmark'));
    await tester.pump();
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    await tester.tap(find.byTooltip('Post actions'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Post'), findsOneWidget);
    expect(find.text('Report'), findsNothing);
    await tester.tap(find.text('Delete Post'));
    await tester.pumpAndSettle();
    expect(selected, PostAction.delete);
  });

  testWidgets('keeps short text close to a single image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 660,
              child: PostCard(
                post: _postWithImage,
                accessToken: 'token',
                isOwnPost: true,
                onAction: (_) {},
                onDownloadImage: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    final textBottom = tester
        .getRect(find.byKey(const Key('post-text-content')))
        .bottom;
    final imageTop = tester
        .getRect(find.byKey(const Key('post-single-image-frame')))
        .top;
    expect(imageTop - textBottom, moreOrLessEquals(10, epsilon: 0.1));
  });

  testWidgets('offers report without a block action for another user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: SizedBox(
            width: 660,
            child: PostCard(
              post: _post,
              accessToken: 'token',
              isOwnPost: false,
              onAction: (_) {},
              onDownloadImage: (_) async {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Post actions'));
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Block User'), findsNothing);
  });
}

final _post = PublicPost(
  id: '41',
  author: PublicUser(
    id: '7',
    username: 'retro_user',
    displayName: 'Retro User',
    createdAt: DateTime.utc(2026, 8, 9),
  ),
  body: 'Hello everyone',
  images: const [],
  createdAt: DateTime.utc(2026, 8, 9, 9),
);

final _postWithImage = PublicPost(
  id: '42',
  author: _post.author,
  body: 'A short post.',
  images: const [
    PublicPostImage(
      id: 'image-1',
      position: 0,
      contentType: 'image/jpeg',
      byteSize: 1024,
      url: '/api/v1/uploads/image-1',
    ),
  ],
  createdAt: DateTime.utc(2026, 8, 9, 10),
);
