import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/posts/domain/public_post.dart';
import 'package:instant_chat/features/posts/presentation/explore_feed.dart';
import 'package:instant_chat/features/posts/presentation/explore_header.dart';
import 'package:instant_chat/features/users/domain/public_user.dart';

void main() {
  test('contacts feed includes only contact posts', () {
    final result = filterExplorePosts(
      _posts,
      selectedTab: ExploreFeedTab.contacts,
      contactUserIds: const {'2'},
    );

    expect(result.map((post) => post.id), ['b']);
  });

  test('for you feed includes every public post', () {
    final result = filterExplorePosts(
      _posts,
      selectedTab: ExploreFeedTab.forYou,
      contactUserIds: const {},
    );

    expect(result.map((post) => post.id), ['a', 'b']);
  });

  test('finds the selected post without changing feed order', () {
    expect(findExplorePost(_posts, 'b'), same(_posts[1]));
    expect(findExplorePost(_posts, 'missing'), isNull);
  });
}

final _posts = [
  PublicPost(
    id: 'a',
    author: PublicUser(
      id: '1',
      username: 'alice_w',
      displayName: 'Alice White',
      createdAt: DateTime.utc(2026),
    ),
    body: 'Mountain light this morning',
    images: const [],
    createdAt: DateTime.utc(2026, 8, 10),
  ),
  PublicPost(
    id: 'b',
    author: PublicUser(
      id: '2',
      username: 'bob',
      displayName: 'Bob Green',
      createdAt: DateTime.utc(2026),
    ),
    body: 'A quiet day',
    images: const [],
    createdAt: DateTime.utc(2026, 8, 10),
  ),
];
