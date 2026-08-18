import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/domain/post_comment.dart';
import 'package:instant_chat/features/posts/presentation/post_comment_row.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  testWidgets('reveals replies five at a time and collapses the thread', (
    tester,
  ) async {
    final root = _comment(id: 'root', body: 'Root comment');
    final replies = List.generate(
      12,
      (index) => _comment(
        id: 'reply-${index + 1}',
        body: 'Reply ${index + 1}',
        parentCommentId: root.id,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCommentRow(
              comment: root,
              replies: replies,
              accessToken: 'access-token',
              currentUserId: 'other-user',
              onReply: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Show 12 replies'), findsOneWidget);
    expect(find.text('Reply 1'), findsNothing);

    await tester.tap(find.byKey(const Key('post-comment-show-replies-root')));
    await tester.pump();

    expect(find.text('Reply 5'), findsOneWidget);
    expect(find.text('Reply 6'), findsNothing);
    expect(find.text('Show 5 more'), findsOneWidget);
    expect(find.text('Collapse'), findsOneWidget);

    await _tapMore(tester);

    expect(find.text('Reply 10'), findsOneWidget);
    expect(find.text('Reply 11'), findsNothing);
    expect(find.text('Show 2 more'), findsOneWidget);

    await _tapMore(tester);

    expect(find.text('Reply 12'), findsOneWidget);
    expect(
      find.byKey(const Key('post-comment-show-more-replies-root')),
      findsNothing,
    );

    final collapse = find.byKey(
      const Key('post-comment-collapse-replies-root'),
    );
    await tester.ensureVisible(collapse);
    await tester.tap(collapse);
    await tester.pump();

    expect(find.text('Reply 1'), findsNothing);
    expect(find.text('Reply 12'), findsNothing);
    expect(find.text('Show 12 replies'), findsOneWidget);
  });
}

Future<void> _tapMore(WidgetTester tester) async {
  final showMore = find.byKey(const Key('post-comment-show-more-replies-root'));
  await tester.ensureVisible(showMore);
  await tester.tap(showMore);
  await tester.pump();
}

PostComment _comment({
  required String id,
  required String body,
  String? parentCommentId,
}) {
  return PostComment(
    id: id,
    postId: 'post-1',
    parentCommentId: parentCommentId,
    author: _author,
    body: body,
    createdAt: DateTime.utc(2026, 8, 18, 10),
  );
}

final _author = PublicUser(
  id: 'author-1',
  username: 'author',
  displayName: 'Author',
  createdAt: DateTime.utc(2026, 8, 18),
);
