import 'package:flutter/material.dart';
import 'package:instant_chat/app/app_localizations.dart';

enum SettingsCategory {
  general(Icons.settings_outlined),
  appearance(Icons.palette_outlined),
  messages(Icons.chat_bubble_outline_rounded),
  notifications(Icons.notifications_none_rounded),
  privacy(Icons.shield_outlined),
  storage(Icons.storage_outlined);

  const SettingsCategory(this.icon);

  final IconData icon;

  String label(AppLocalizations localizations) => switch (this) {
    SettingsCategory.general => localizations.general,
    SettingsCategory.appearance => localizations.appearance,
    SettingsCategory.messages => localizations.messages,
    SettingsCategory.notifications => localizations.notifications,
    SettingsCategory.privacy => localizations.privacy,
    SettingsCategory.storage => localizations.storage,
  };
}
