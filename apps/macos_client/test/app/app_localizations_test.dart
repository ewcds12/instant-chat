import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/app_localizations.dart';

void main() {
  test('provides English, Japanese, and Simplified Chinese copy', () {
    expect(
      const AppLocalizations(AppLanguage.english).launchAtLogin,
      'Launch at login',
    );
    expect(
      const AppLocalizations(AppLanguage.japanese).launchAtLogin,
      'ログイン時に起動',
    );
    expect(
      const AppLocalizations(AppLanguage.simplifiedChinese).launchAtLogin,
      '登录时启动',
    );
  });

  test('falls back to English for unknown platform language codes', () {
    expect(AppLanguage.fromPlatformCode('unsupported'), AppLanguage.english);
  });

  test('covers app-owned copy across every product area', () {
    const japanese = AppLocalizations(AppLanguage.japanese);
    const chinese = AppLocalizations(AppLanguage.simplifiedChinese);

    expect(japanese.ui('Contact Info'), '連絡先情報');
    expect(japanese.ui('Send message'), 'メッセージを送信');
    expect(japanese.ui('Show more'), 'もっと見る');
    expect(japanese.ui('Daily Brief'), 'デイリーブリーフ');
    expect(japanese.ui('Personal details'), '個人情報');
    expect(chinese.ui('Contact Info'), '联系人信息');
    expect(chinese.ui('Send message'), '发送消息');
    expect(chinese.ui('Show more'), '展开');
    expect(chinese.ui('Daily Brief'), '每日简报');
    expect(chinese.ui('Personal details'), '个人资料');
  });

  test('keeps user and remote content unchanged', () {
    const content = 'A user-written message, post, comment, or headline.';
    for (final language in AppLanguage.values) {
      expect(AppLocalizations(language).ui(content), content);
    }
  });

  test('every literal ui lookup has a translation', () {
    const localizations = AppLocalizations(AppLanguage.english);
    final missing = <String>[];
    for (final file in _dartSourceFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in _uiLookupPatterns) {
        for (final match in pattern.allMatches(source)) {
          final key = match.group(1)!;
          if (!localizations.hasUiTranslation(key)) {
            missing.add('${file.path}: $key');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('presentation code has no direct English widget literals', () {
    final violations = <String>[];
    for (final file in _presentationSourceFiles()) {
      final source = file.readAsStringSync();
      for (final pattern in _directUiLiteralPatterns) {
        for (final match in pattern.allMatches(source)) {
          violations.add('${file.path}: ${match.group(1)}');
        }
      }
    }
    expect(violations, isEmpty);
  });
}

final _uiLookupPatterns = [
  RegExp(r"\.ui\(\s*'([^']+)'\s*\)"),
  RegExp(r'\.ui\(\s*"([^"]+)"\s*\)'),
];

final _directUiLiteralPatterns = [
  RegExp(
    r'''(?:Text|SelectableText)\(\s*(?:const\s+)?["']([A-Za-z][^"']*)["']''',
    multiLine: true,
  ),
  RegExp(
    r'''(?:hintText|labelText|tooltip|semanticLabel):\s*["']([A-Za-z][^"']*)["']''',
    multiLine: true,
  ),
];

Iterable<File> _dartSourceFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

Iterable<File> _presentationSourceFiles() => Directory('lib/features')
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (file) =>
          file.path.endsWith('.dart') && file.path.contains('/presentation/'),
    );
