import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';
import 'package:instant_chat/features/settings/presentation/language_setting.dart';

void main() {
  testWidgets('switches language immediately and saves the selection', (
    tester,
  ) async {
    final platform = _FakeAppLanguagePlatform();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLanguagePlatformProvider.overrideWithValue(platform)],
        child: const _LocalizedLanguageSetting(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-language-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-language-ja')));
    await tester.pumpAndSettle();

    expect(platform.selections, [AppLanguage.japanese]);
    expect(find.text('言語'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
  });
}

class _LocalizedLanguageSetting extends ConsumerWidget {
  const _LocalizedLanguageSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(appLanguageProvider).value ?? AppLanguage.english;
    return MaterialApp(
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((item) => item.locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const Scaffold(body: LanguageSetting()),
    );
  }
}

class _FakeAppLanguagePlatform implements AppLanguagePlatform {
  final _changes = StreamController<AppLanguage>.broadcast();
  final selections = <AppLanguage>[];
  var language = AppLanguage.english;

  @override
  Stream<AppLanguage> get languageChanges => _changes.stream;

  @override
  Future<AppLanguage> getLanguage() async => language;

  @override
  Future<void> setLanguage(AppLanguage selected) async {
    language = selected;
    selections.add(selected);
    _changes.add(selected);
  }

  @override
  Future<void> dispose() => _changes.close();
}
