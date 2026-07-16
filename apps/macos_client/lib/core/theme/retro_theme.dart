import 'package:flutter/material.dart';

abstract final class RetroMetrics {
  static const border = 2.0;
  static const corner = 3.0;
  static const spaceSmall = 8.0;
  static const spaceMedium = 16.0;
  static const spaceLarge = 24.0;
  static const maxAuthPanelWidth = 460.0;
  static const maxPanelWidth = 680.0;
  static const statusIconSize = 18.0;
}

abstract final class RetroTheme {
  static const _canvas = Color(0xFFCEC7B5);
  static const _panel = Color(0xFFF1EBD9);
  static const _ink = Color(0xFF17201C);
  static const _terminalGreen = Color(0xFF25734A);
  static const _amber = Color(0xFFC37824);
  static const _danger = Color(0xFFA43A32);

  static final data = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _canvas,
    fontFamily: 'Menlo',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _terminalGreen,
      onPrimary: _panel,
      secondary: _amber,
      onSecondary: _ink,
      error: _danger,
      onError: _panel,
      surface: _panel,
      onSurface: _ink,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 13, height: 1.5),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _ink,
        foregroundColor: _panel,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide(color: _ink, width: RetroMetrics.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide(color: _ink, width: RetroMetrics.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide(
          color: _terminalGreen,
          width: RetroMetrics.border,
        ),
      ),
    ),
  );
}
