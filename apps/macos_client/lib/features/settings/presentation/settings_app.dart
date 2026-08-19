import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';
import 'package:instant_chat/core/platform/macos_app_language.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/settings/presentation/settings_window_page.dart';

class SettingsApp extends ConsumerWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(appLanguageProvider).value ?? AppLanguage.english;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.settingsTitle,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((item) => item.locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: RetroTheme.data,
      home: const SettingsWindowPage(),
    );
  }
}
