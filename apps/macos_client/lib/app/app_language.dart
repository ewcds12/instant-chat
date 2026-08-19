import 'package:flutter/widgets.dart';

enum AppLanguage {
  english('en', Locale('en', 'US'), 'English'),
  japanese('ja', Locale('ja'), '日本語'),
  simplifiedChinese(
    'zh-Hans',
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    '简体中文',
  );

  const AppLanguage(this.platformCode, this.locale, this.nativeLabel);

  final String platformCode;
  final Locale locale;
  final String nativeLabel;

  static AppLanguage fromPlatformCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.platformCode == code,
      orElse: () => AppLanguage.english,
    );
  }
}
