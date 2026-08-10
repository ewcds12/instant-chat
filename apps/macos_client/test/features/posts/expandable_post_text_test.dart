import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/presentation/expandable_post_text.dart';

void main() {
  testWidgets('long post text expands and collapses', (tester) async {
    await _pumpText(tester, _longText);

    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('Show less'), findsNothing);
    expect(_postText(tester).maxLines, RetroMetrics.explorePostCollapsedLines);
    expect(
      find.descendant(
        of: find.byType(ExpandablePostText),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Show more'));
    await tester.pump();
    expect(find.text('Show less'), findsOneWidget);
    expect(_postText(tester).maxLines, isNull);
    expect(
      find.descendant(
        of: find.byType(ExpandablePostText),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Show less'));
    await tester.pump();
    expect(find.text('Show more'), findsOneWidget);
    expect(_postText(tester).maxLines, RetroMetrics.explorePostCollapsedLines);
  });

  testWidgets('short post text does not show a toggle', (tester) async {
    await _pumpText(tester, 'A short post.');

    expect(find.byKey(const Key('post-text-toggle')), findsNothing);
    expect(
      tester.getSize(find.byType(ExpandablePostText)).height,
      lessThan(30),
    );
    expect(
      find.descendant(
        of: find.byType(ExpandablePostText),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });
}

Text _postText(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('post-text-content')));
}

Future<void> _pumpText(WidgetTester tester, String text) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 240, child: ExpandablePostText(text: text)),
        ),
      ),
    ),
  );
}

const _longText =
    'Today is your last dance. You gave us so much, and we should have '
    'offered you a better ending. Putting words to everything you brought '
    'over the years is difficult. Your story deserves to be remembered.';
