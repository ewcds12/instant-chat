import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/features/settings/presentation/settings_app.dart';

void main() {
  testWidgets('switches and filters settings categories', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SettingsApp());
    await tester.pumpAndSettle();

    expect(find.text('General'), findsNWidgets(2));
    expect(find.text('Launch at login'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-category-appearance')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('settings-content-title'))).data,
      'Appearance',
    );
    expect(
      find.text('Appearance settings will be added here.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('settings-search-field')),
      'privacy',
    );
    await tester.pump();

    expect(find.byKey(const Key('settings-category-privacy')), findsOneWidget);
    expect(find.byKey(const Key('settings-category-storage')), findsNothing);
  });
}
