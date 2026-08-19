import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_chat/core/platform/macos_launch_at_login.dart';
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
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
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
          launchAtLoginPlatformProvider.overrideWithValue(platform),
          linkOpeningPreferenceProvider.overrideWithValue(
            _FakeLinkOpeningPreference(),
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
          launchAtLoginPlatformProvider.overrideWithValue(
            _FakeLaunchAtLoginPlatform(),
          ),
          linkOpeningPreferenceProvider.overrideWithValue(preference),
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
}

class _FakeLaunchAtLoginPlatform implements LaunchAtLoginPlatform {
  var status = LaunchAtLoginStatus.disabled;
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
