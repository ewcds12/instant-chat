import 'package:flutter/material.dart';

abstract final class RetroMetrics {
  static const border = 1.0;
  static const corner = 10.0;
  static const spaceSmall = 8.0;
  static const spaceMedium = 16.0;
  static const spaceLarge = 24.0;
  static const composerControlHeight = 34.0;
  static const maxAuthPanelWidth = 420.0;
  static const maxPanelWidth = 760.0;
  static const statusIconSize = 20.0;
}

abstract final class RetroTheme {
  static const _canvas = Color(0xFFF5F6F8);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceMuted = Color(0xFFF4F5F7);
  static const _surfaceSelected = Color(0xFFEFF5FF);
  static const _ink = Color(0xFF17191C);
  static const _mutedInk = Color(0xFF6E737B);
  static const _primary = Color(0xFF2F6FE4);
  static const _primaryDark = Color(0xFF2457B6);
  static const _danger = Color(0xFFC9342F);
  static const _dangerLight = Color(0xFFFCE8E7);
  static const _divider = Color(0xFFE4E7EB);

  static final data = ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.macOS,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _canvas,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: _surface,
      primaryContainer: _surfaceSelected,
      onPrimaryContainer: _primaryDark,
      secondary: _primaryDark,
      onSecondary: _surface,
      secondaryContainer: _surfaceSelected,
      onSecondaryContainer: _ink,
      error: _danger,
      onError: _surface,
      errorContainer: _dangerLight,
      onErrorContainer: _ink,
      surface: _surface,
      onSurface: _ink,
      surfaceContainerLowest: _surface,
      surfaceContainerLow: _canvas,
      surfaceContainer: _surfaceMuted,
      surfaceContainerHigh: Color(0xFFE9EBEF),
      surfaceContainerHighest: Color(0xFFE2E5E9),
      onSurfaceVariant: _mutedInk,
      outline: Color(0xFFB8BDC5),
      outlineVariant: _divider,
      inverseSurface: _ink,
      onInverseSurface: _surface,
      inversePrimary: Color(0xFFAAC7FF),
      shadow: Color(0x1A000000),
      scrim: _ink,
      surfaceTint: Colors.transparent,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, height: 1.35),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _surface,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _primary),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: _primary,
      selectionColor: Color(0x553B82F6),
      selectionHandleColor: _primary,
    ),
    dividerTheme: const DividerThemeData(
      color: _divider,
      thickness: RetroMetrics.border,
      space: RetroMetrics.border,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: _surfaceMuted,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(RetroMetrics.corner)),
        borderSide: BorderSide(color: _primary),
      ),
      labelStyle: TextStyle(color: _mutedInk),
      hintStyle: TextStyle(color: _mutedInk),
    ),
  );
}
