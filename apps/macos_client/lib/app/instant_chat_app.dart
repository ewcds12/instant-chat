import 'package:flutter/material.dart';
import 'package:instant_chat/core/theme/retro_theme.dart';
import 'package:instant_chat/features/system_status/presentation/system_status_page.dart';

class InstantChatApp extends StatelessWidget {
  const InstantChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instant Chat',
      theme: RetroTheme.data,
      home: const SystemStatusPage(),
    );
  }
}
