import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/presentation/explore_header.dart';

void main() {
  testWidgets('switches feed tabs and opens the composer', (tester) async {
    ExploreFeedTab? selected;
    var createCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: RetroTheme.data,
        home: Scaffold(
          body: ExploreHeader(
            selectedTab: ExploreFeedTab.forYou,
            onTabSelected: (value) => selected = value,
            onCreate: () => createCount += 1,
            onRefresh: () {},
            onBlockedUsers: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('explore-tab-contacts')));
    expect(selected, ExploreFeedTab.contacts);

    await tester.tap(find.byKey(const Key('explore-compose-button')));
    expect(createCount, 1);
  });
}
