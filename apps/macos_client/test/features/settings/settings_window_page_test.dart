import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_close_window_behavior.dart';
import 'package:instant_chat/core/platform/macos_dock_visibility.dart';
import 'package:instant_chat/core/platform/macos_launch_at_login.dart';
import 'package:instant_chat/core/platform/macos_spell_check.dart';
import 'package:instant_chat/core/platform/macos_url_launcher.dart';
import 'package:instant_chat/features/settings/presentation/settings_app.dart';

void main() {
  testWidgets('switches and filters settings categories', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
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

  testWidgets('reads and updates Launch at login', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final platform = _FakeLaunchAtLoginPlatform();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(platform),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    var launchSwitch = tester.widget<Switch>(
      find.byKey(const Key('launch-at-login-switch')),
    );
    expect(launchSwitch.value, isFalse);

    await tester.tap(find.byKey(const Key('launch-at-login-switch')));
    await tester.pumpAndSettle();

    expect(platform.requestedValues, [true]);
    launchSwitch = tester.widget<Switch>(
      find.byKey(const Key('launch-at-login-switch')),
    );
    expect(launchSwitch.value, isTrue);
  });

  testWidgets('explains when Launch at login needs an installed app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(status: LaunchAtLoginStatus.unavailable),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Available after installing Instant Chat.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('launch-at-login-switch')))
          .onChanged,
      isNull,
    );
  });

  testWidgets('reads and updates the default-browser preference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preference = _FakeLinkOpeningPreference(enabled: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(preference),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    var browserSwitch = tester.widget<Switch>(
      find.byKey(const Key('open-links-in-default-browser-switch')),
    );
    expect(browserSwitch.value, isFalse);

    await tester.tap(
      find.byKey(const Key('open-links-in-default-browser-switch')),
    );
    await tester.pumpAndSettle();

    expect(preference.requestedValues, [true]);
    browserSwitch = tester.widget<Switch>(
      find.byKey(const Key('open-links-in-default-browser-switch')),
    );
    expect(browserSwitch.value, isTrue);
  });

  testWidgets('reads and updates the Dock preference', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final platform = _FakeDockVisibilityPlatform(enabled: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(platform),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    var dockSwitch = tester.widget<Switch>(
      find.byKey(const Key('keep-app-in-dock-switch')),
    );
    expect(dockSwitch.value, isFalse);

    await tester.tap(find.byKey(const Key('keep-app-in-dock-switch')));
    await tester.pumpAndSettle();

    expect(platform.requestedValues, [true]);
    dockSwitch = tester.widget<Switch>(
      find.byKey(const Key('keep-app-in-dock-switch')),
    );
    expect(dockSwitch.value, isTrue);
  });

  testWidgets('reads and updates the close-window behavior', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final platform = _FakeCloseWindowBehaviorPlatform(
      behavior: CloseWindowBehavior.quitApplication,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(platform),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(
            _FakeSpellCheckPlatform(),
          ),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('close-window-current-value')))
          .data,
      'Quit Instant Chat',
    );

    await tester.tap(find.byKey(const Key('close-window-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('close-window-keep_running')));
    await tester.pumpAndSettle();

    expect(platform.requestedValues, [CloseWindowBehavior.keepRunning]);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('close-window-current-value')))
          .data,
      'Keep Instant Chat running',
    );
  });

  testWidgets('reads and updates spelling while typing', (tester) async {
    tester.view.physicalSize = const Size(920, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final platform = _FakeSpellCheckPlatform(enabled: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closeWindowBehaviorPlatformProvider.overrideWithValue(
            _FakeCloseWindowBehaviorPlatform(),
          ),
          dockVisibilityPlatformProvider.overrideWithValue(
            _FakeDockVisibilityPlatform(),
          ),
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
          ),
          spellCheckPlatformProvider.overrideWithValue(platform),
        ],
        child: const SettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    var spellingSwitch = tester.widget<Switch>(
      find.byKey(const Key('check-spelling-switch')),
    );
    expect(spellingSwitch.value, isFalse);

    await tester.tap(find.byKey(const Key('check-spelling-switch')));
    await tester.pumpAndSettle();

    expect(platform.requestedValues, [true]);
    spellingSwitch = tester.widget<Switch>(
      find.byKey(const Key('check-spelling-switch')),
    );
    expect(spellingSwitch.value, isTrue);
  });
}

class _FakeCloseWindowBehaviorPlatform implements CloseWindowBehaviorPlatform {
  _FakeCloseWindowBehaviorPlatform({
    this.behavior = CloseWindowBehavior.keepRunning,
  });

  CloseWindowBehavior behavior;
  final requestedValues = <CloseWindowBehavior>[];

  @override
  Future<CloseWindowBehavior> getBehavior() async => behavior;

  @override
  Future<void> setBehavior(CloseWindowBehavior behavior) async {
    requestedValues.add(behavior);
    this.behavior = behavior;
  }
}

class _FakeDockVisibilityPlatform implements DockVisibilityPlatform {
  _FakeDockVisibilityPlatform({this.enabled = true});

  bool enabled;
  final requestedValues = <bool>[];

  @override
  Future<bool> getKeepAppInDock() async => enabled;

  @override
  Future<void> setKeepAppInDock(bool enabled) async {
    requestedValues.add(enabled);
    this.enabled = enabled;
  }
}

class _FakeLaunchAtLoginPlatform implements LaunchAtLoginPlatform {
  _FakeLaunchAtLoginPlatform({this.status = LaunchAtLoginStatus.disabled});

  LaunchAtLoginStatus status;
  final requestedValues = <bool>[];

  @override
  Future<LaunchAtLoginStatus> getStatus() async => status;

  @override
  Future<LaunchAtLoginStatus> setEnabled(bool enabled) async {
    requestedValues.add(enabled);
    status = enabled
        ? LaunchAtLoginStatus.enabled
        : LaunchAtLoginStatus.disabled;
    return status;
  }
}

class _FakeLinkOpeningPreference implements LinkOpeningPreference {
  _FakeLinkOpeningPreference({this.enabled = true});

  bool enabled;
  final requestedValues = <bool>[];

  @override
  Future<bool> getOpenLinksInDefaultBrowser() async => enabled;

  @override
  Future<void> setOpenLinksInDefaultBrowser(bool enabled) async {
    requestedValues.add(enabled);
    this.enabled = enabled;
  }
}

class _FakeSpellCheckPlatform implements SpellCheckPlatform {
  _FakeSpellCheckPlatform({this.enabled = true});

  bool enabled;
  final requestedValues = <bool>[];

  @override
  Stream<bool> get enabledChanges => const Stream.empty();

  @override
  Future<bool> getEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    requestedValues.add(enabled);
    this.enabled = enabled;
  }

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
    Locale locale,
    String text,
  ) async => const [];

  @override
  Future<void> dispose() async {}
}
