import 'package:flutter/widgets.dart';
import 'package:instant_chat/app/app_language.dart';
import 'package:instant_chat/app/translations/common_translations.dart';
import 'package:instant_chat/app/translations/contact_translations.dart';
import 'package:instant_chat/app/translations/message_translations.dart';
import 'package:instant_chat/app/translations/post_translations.dart';
import 'package:instant_chat/app/translations/profile_translations.dart';

const _uiTranslations = <String, List<String>>{
  ...commonTranslations,
  ...contactTranslations,
  ...messageTranslations,
  ...postTranslations,
  ...profileTranslations,
};

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.english);
  }

  String get appTitle => _pick('Instant Chat', 'Instant Chat', 'Instant Chat');
  String get settingsTitle => _pick('Settings', '設定', '设置');
  String get search => _pick('Search', '検索', '搜索');
  String get noSettingsFound =>
      _pick('No settings found', '設定が見つかりません', '未找到设置');
  String get general => _pick('General', '一般', '通用');
  String get appearance => _pick('Appearance', '外観', '外观');
  String get messages => _pick('Messages', 'メッセージ', '消息');
  String get notifications => _pick('Notifications', '通知', '通知');
  String get privacy => _pick('Privacy', 'プライバシー', '隐私');
  String get storage => _pick('Storage', 'ストレージ', '存储');
  String settingsComingSoon(String category) => _pick(
    '$category settings will be added here.',
    '$categoryの設定は今後追加されます。',
    '$category设置将在这里添加。',
  );

  String get launchAtLogin => _pick('Launch at login', 'ログイン時に起動', '登录时启动');
  String get launchAtLoginApproval => _pick(
    'Approval is required in System Settings.',
    'システム設定での許可が必要です。',
    '需要在系统设置中批准。',
  );
  String get launchAtLoginUnavailable => _pick(
    'Available after installing Instant Chat.',
    'Instant Chat のインストール後に利用できます。',
    '安装 Instant Chat 后可用。',
  );
  String get launchAtLoginUnsupported => _pick(
    'Requires macOS 13 or later.',
    'macOS 13 以降が必要です。',
    '需要 macOS 13 或更高版本。',
  );
  String get unableToUpdateSetting =>
      _pick('Unable to update this setting.', 'この設定を更新できません。', '无法更新此设置。');
  String get launchAtLoginUpdateFailed => _pick(
    'Could not update Launch at login.',
    'ログイン時の起動を更新できませんでした。',
    '无法更新登录时启动。',
  );
  String get openLinksInDefaultBrowser =>
      _pick('Open links in default browser', 'リンクをデフォルトブラウザで開く', '在默认浏览器中打开链接');
  String get linkSettingUpdateFailed => _pick(
    'Could not update link settings.',
    'リンク設定を更新できませんでした。',
    '无法更新链接设置。',
  );
  String get keepAppInDock =>
      _pick('Keep app in Dock', 'Dock にアプリを表示', '在程序坞中保留应用');
  String get dockSettingUpdateFailed => _pick(
    'Could not update Dock settings.',
    'Dock 設定を更新できませんでした。',
    '无法更新程序坞设置。',
  );
  String get languageSettingLabel => _pick('Language', '言語', '语言');
  String get languageSettingUpdateFailed => _pick(
    'Could not update the app language.',
    'アプリの言語を更新できませんでした。',
    '无法更新应用语言。',
  );
  String get closeWindow => _pick('Close window', 'ウインドウを閉じる', '关闭窗口');
  String get keepRunning => _pick(
    'Keep Instant Chat running',
    'Instant Chat を実行したままにする',
    '保持 Instant Chat 运行',
  );
  String get quitApplication =>
      _pick('Quit Instant Chat', 'Instant Chat を終了', '退出 Instant Chat');
  String get closeWindowTooltip => _pick(
    'Choose what happens when the window closes',
    'ウインドウを閉じたときの動作を選択',
    '选择关闭窗口时的操作',
  );
  String get closeWindowSettingUpdateFailed => _pick(
    'Could not update close-window settings.',
    'ウインドウを閉じる設定を更新できませんでした。',
    '无法更新关闭窗口设置。',
  );
  String get checkSpelling =>
      _pick('Check spelling while typing', '入力中にスペルをチェック', '输入时检查拼写');

  String get id => _pick('ID', 'ID', 'ID');
  String get displayName => _pick('Display name', '表示名', '显示名称');
  String get password => _pick('Password', 'パスワード', '密码');
  String get pleaseWait => _pick('Please wait…', 'お待ちください…', '请稍候…');
  String get createAccount => _pick('Create account', 'アカウントを作成', '创建账户');
  String get signIn => _pick('Sign in', 'サインイン', '登录');
  String get backToSignIn => _pick('Back to sign in', 'サインインに戻る', '返回登录');
  String get createAnAccount => _pick('Create an account', 'アカウントを作成', '创建账户');
  String get displayNameValidation =>
      _pick('Use 2 to 80 characters.', '2〜80文字で入力してください。', '请输入 2 到 80 个字符。');
  String get usernameValidation => _pick(
    'Use 3 to 32 lowercase letters, numbers, or underscores.',
    '3〜32文字の小文字、数字、またはアンダースコアを使用してください。',
    '请使用 3 到 32 个小写字母、数字或下划线。',
  );
  String get chats => _pick('Chats', 'チャット', '聊天');
  String get contacts => _pick('Contacts', '連絡先', '联系人');
  String get explore => _pick('Explore', '見つける', '探索');
  String get settings => _pick('Settings', '設定', '设置');

  String ui(String english) {
    final translation = _uiTranslations[english];
    if (translation == null) {
      return english;
    }
    return switch (language) {
      AppLanguage.english => english,
      AppLanguage.japanese => translation[0],
      AppLanguage.simplifiedChinese => translation[1],
    };
  }

  bool hasUiTranslation(String english) => _uiTranslations.containsKey(english);

  String messageRecipient(String name) =>
      _pick('Message $name', '$nameにメッセージ', '发送消息给 $name');

  String searchMessagesWith(String name) =>
      _pick('Search messages with $name', '$nameとのメッセージを検索', '搜索与 $name 的消息');

  String deleteContactDescription(String name) => _pick(
    'Delete $name from your contacts and remove this chat from Chats? Message history will return if you add each other again.',
    '$nameを連絡先から削除し、このチャットをチャット一覧から取り除きますか？再度連絡先に追加すると履歴は元に戻ります。',
    '要从联系人中删除 $name，并从聊天列表移除此聊天吗？重新添加好友后，历史记录会恢复。',
  );

  String resultCount(int count, {required bool partial}) => _pick(
    partial ? '$count results so far' : '$count results',
    partial ? '現在$count件の結果' : '$count件の結果',
    partial ? '目前 $count 条结果' : '$count 条结果',
  );

  String friendRequestCount(int count) => _pick(
    count == 1 ? '1 Friend Request' : '$count Friend Requests',
    '友達リクエスト $count件',
    '$count 个好友申请',
  );

  String pendingCount(int count) =>
      _pick('$count pending', '$count件保留中', '$count 个待处理');

  String linksCount(int count) =>
      _pick('Links ($count)', 'リンク（$count）', '链接（$count）');

  String imagePosition(int index, int total) =>
      _pick('$index of $total', '$total枚中$index枚目', '$index / $total');

  String recalledMessage(String senderName, {required bool isMine}) => _pick(
    isMine ? 'You recalled a message' : '$senderName recalled a message',
    isMine ? 'メッセージの送信を取り消しました' : '$senderNameがメッセージの送信を取り消しました',
    isMine ? '你撤回了一条消息' : '$senderName 撤回了一条消息',
  );

  String photoCount(int count) =>
      _pick('Photo $count/4', '写真 $count/4', '图片 $count/4');

  String commentCount(int count) => _pick(
    count == 1 ? '1 Comment' : '$count Comments',
    'コメント $count件',
    '$count 条评论',
  );

  String replyingTo(String name) =>
      _pick('Replying to $name', '$nameに返信中', '正在回复 $name');

  String showReplyCount(int count) => _pick(
    'Show $count ${count == 1 ? 'reply' : 'replies'}',
    '返信を$count件表示',
    '展开 $count 条回复',
  );

  String showMoreReplies(int count) =>
      _pick('Show $count more', 'さらに$count件表示', '再展开 $count 条');

  String openNewsItem(String title) =>
      _pick('Open $title', '$titleを開く', '打开 $title');

  String contactSemantics(String name) =>
      _pick('Contact $name', '連絡先 $name', '联系人 $name');

  String relativeMinutes(int count) =>
      _pick('${count}m', '$count分', '$count 分钟');

  String relativeHours(int count) =>
      _pick('${count}h', '$count時間', '$count 小时');

  String relativeDays(int count) => _pick('${count}d', '$count日', '$count 天');

  String yesterdayAt(String time) =>
      _pick('Yesterday $time', '昨日 $time', '昨天 $time');

  String weekdayAt(int weekday, String time) {
    const english = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const japanese = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    const chinese = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final index = weekday - 1;
    return '${switch (language) {
      AppLanguage.english => english[index],
      AppLanguage.japanese => japanese[index],
      AppLanguage.simplifiedChinese => chinese[index],
    }} $time';
  }

  String fullDateTime(DateTime value, String time) => switch (language) {
    AppLanguage.english =>
      '${_englishMonth(value.month)} ${value.day}, ${value.year} $time',
    AppLanguage.japanese => '${value.year}年${value.month}月${value.day}日 $time',
    AppLanguage.simplifiedChinese =>
      '${value.year}年${value.month}月${value.day}日 $time',
  };

  String _englishMonth(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  String _pick(String english, String japanese, String simplifiedChinese) {
    return switch (language) {
      AppLanguage.english => english,
      AppLanguage.japanese => japanese,
      AppLanguage.simplifiedChinese => simplifiedChinese,
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any(
      (language) => language.locale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final language = switch (locale.languageCode) {
      'ja' => AppLanguage.japanese,
      'zh' => AppLanguage.simplifiedChinese,
      _ => AppLanguage.english,
    };
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
