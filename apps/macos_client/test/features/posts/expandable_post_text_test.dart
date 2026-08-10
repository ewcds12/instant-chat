import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/posts/presentation/expandable_post_text.dart';

void main() {
  testWidgets('long post text expands and collapses', (tester) async {
    await _pumpText(tester, _longText);

    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('Show less'), findsNothing);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).maxLines,
      RetroMetrics.explorePostCollapsedLines,
    );

    await tester.tap(find.text('Show more'));
    await tester.pump();
    expect(find.text('Show less'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).maxLines,
      isNull,
    );

    await tester.tap(find.text('Show less'));
    await tester.pump();
    expect(find.text('Show more'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).maxLines,
      RetroMetrics.explorePostCollapsedLines,
    );
  });

  testWidgets('short post text does not show a toggle', (tester) async {
    await _pumpText(tester, 'A short post.');

    expect(find.byKey(const Key('post-text-toggle')), findsNothing);
  });
}

Future<void> _pumpText(WidgetTester tester, String text) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(
        body: SizedBox(width: 240, child: ExpandablePostText(text: text)),
      ),
    ),
  );
}

const _longText =
    'Today is your last dance. You gave us so much, and we should have '
    'offered you a better ending. Putting words to everything you brought '
    'over the years is difficult. Your story deserves to be remembered.';
