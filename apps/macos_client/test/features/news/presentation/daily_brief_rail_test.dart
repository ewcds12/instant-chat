import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/news/domain/daily_brief.dart';
import 'package:instant_chat/features/news/presentation/daily_brief_rail.dart';

void main() {
  testWidgets('renders compact headlines and opens their source', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      _app(
        DailyBriefPanel(
          brief: AsyncData(_brief),
          onRetry: () {},
          onOpen: (url) => opened = url,
        ),
      ),
    );

    expect(find.text('Daily Brief'), findsOneWidget);
    expect(find.text('Solar eclipse'), findsOneWidget);
    expect(find.text('A current event summary.'), findsOneWidget);
    expect(find.text('From Wikipedia'), findsOneWidget);
    final sourceButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'From Wikipedia'),
    );
    expect(
      sourceButton.style?.overlayColor?.resolve({WidgetState.hovered}),
      Colors.transparent,
    );

    await tester.tap(find.text('Solar eclipse'));
    expect(opened, Uri.parse('https://en.wikipedia.org/wiki/Solar_eclipse'));
  });

  testWidgets('shows a retry action for failures', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _app(
        DailyBriefPanel(
          brief: AsyncError(StateError('offline'), StackTrace.empty),
          onRetry: () => retried = true,
          onOpen: (_) {},
        ),
      ),
    );

    expect(find.text('Daily news is unavailable.'), findsOneWidget);
    await tester.tap(find.text('Try Again'));
    expect(retried, isTrue);
  });

  testWidgets('grows a headline row when title and summary wrap', (
    tester,
  ) async {
    const itemId = 'long-headline';
    await tester.pumpWidget(
      _app(
        DailyBriefPanel(
          brief: AsyncData(
            DailyBrief(
              items: [
                DailyNewsItem(
                  id: itemId,
                  title: '2026 East Nusa Tenggara earthquake affects region',
                  summary:
                      'A magnitude-7.7 earthquake strikes off the coast of '
                      'Flores, Indonesia, causing widespread disruption.',
                  source: 'Wikipedia Current Events',
                  url: Uri.parse('https://en.wikipedia.org/wiki/Earthquake'),
                ),
              ],
              updatedAt: DateTime.utc(2026, 8, 17),
            ),
          ),
          onRetry: () {},
          onOpen: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('daily-news-$itemId'))).height,
      greaterThan(RetroMetrics.dailyBriefItemMinHeight),
    );
  });
}

Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: RetroTheme.data,
      home: Scaffold(body: SizedBox(width: 300, height: 650, child: child)),
    ),
  );
}

final _brief = DailyBrief(
  items: [
    DailyNewsItem(
      id: '42',
      title: 'Solar eclipse',
      summary: 'A current event summary.',
      source: 'Wikipedia Current Events',
      url: Uri.parse('https://en.wikipedia.org/wiki/Solar_eclipse'),
    ),
  ],
  updatedAt: DateTime.utc(2026, 8, 14, 8, 30),
);
