import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/auth/presentation/auth_gate.dart';

class InstantChatApp extends StatelessWidget {
  const InstantChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instant Chat',
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      theme: RetroTheme.data,
      home: const AuthGate(),
    );
  }
}
