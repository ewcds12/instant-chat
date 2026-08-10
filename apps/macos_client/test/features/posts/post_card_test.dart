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
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello everyone'), findsOneWidget);
    expect(find.text('Retro User'), findsOneWidget);
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
