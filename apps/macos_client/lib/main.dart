import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instant_chat/app/instant_chat_app.dart';
import 'package:instant_chat/features/settings/presentation/settings_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: InstantChatApp()));
}

@pragma('vm:entry-point')
void settingsMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SettingsApp()));
}
