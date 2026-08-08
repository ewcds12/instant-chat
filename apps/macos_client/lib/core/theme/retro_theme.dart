import 'package:flutter/material.dart';

abstract final class RetroMetrics {
  static const border = 1.0;
  static const corner = 10.0;
  static const cornerLarge = 18.0;
  static const cornerPill = 999.0;
  static const spaceSmall = 8.0;
  static const spaceMedium = 16.0;
  static const spaceLarge = 24.0;
  static const sidebarWidth = 180.0;
  static const conversationColumnWidth = 280.0;
  static const composerControlHeight = 38.0;
  static const composerBarHeight = 40.0;
  static const composerSendDiameter = 28.0;
  static const composerTextSize = 13.0;
  static const composerMaxLines = 8;
  static const composerCornerRadius = 20.0;
  static const composerActionInset = 5.0;
  static const composerExpandedActionHeight = 39.0;
  static const composerExpandedTextHorizontalInset = 12.0;
  static const composerExpandedTextTopInset = 18.0;
  static const composerExpandedTextBottomInset = 2.0;
  static const composerReplyHorizontalInset = 12.0;
  static const composerReplyTopInset = 10.0;
  static const composerReplyTrailingInset = 8.0;
  static const composerReplyCardHorizontalInset = 10.0;
  static const composerReplyCardVerticalInset = 7.0;
  static const composerReplyCardRadius = 7.0;
  static const composerReplyAccentWidth = 3.0;
  static const composerReplyLineGap = 2.0;
  static const composerImagePreviewSize = 88.0;
  static const composerImagePreviewRadius = 14.0;
  static const composerImagePreviewInset = 12.0;
  static const composerImageRemoveDiameter = 22.0;
  static const composerHorizontalInset = 20.0;
  static const composerTopInset = 4.0;
  static const composerBottomInset = 12.0;
  static const authWindowWidth = 280.0;
  static const authWindowHeight = 360.0;
  static const authFormMaxWidth = 210.0;
  static const authFieldHeight = 38.0;
  static const authButtonHeight = 36.0;
  static const authContentTopInset = 90.0;
  static const maxPanelWidth = 760.0;
  static const maxProfilePanelWidth = 480.0;
  static const maxProfilePhotoCropPanelWidth = 420.0;
  static const contactDirectoryWidth = conversationColumnWidth;
  static const contactLayoutBreakpoint = 760.0;
  static const contactAvatarRadius = 24.0;
  static const contactDirectoryAvatarRadius = 20.0;
  static const contactDetailAvatarRadius = 36.0;
  static const contactDetailHeroAvatarRadius = 38.0;
  static const contactDetailContentMaxWidth = 980.0;
  static const contactDetailContentHorizontalInset = 24.0;
  static const contactDetailContentVerticalInset = 18.0;
  static const contactDetailHeroHeight = 112.0;
  static const contactDetailMessageHeight = 36.0;
  static const contactMessageSearchMaxWidth = 780.0;
  static const contactMessageSearchMaxHeight = 560.0;
  static const contactSharedThumbnailGap = 12.0;
  static const contactSharedThumbnailRadius = 10.0;
  static const contactSharedThumbnailExtent = 164.0;
  static const contactSharedRowHeight = 54.0;
  static const contactSharedStatusHeight = 84.0;
  static const contactRowHeight = 62.0;
  static const contactSearchHeight = 36.0;
  static const contactDetailHeaderHeight = 56.0;
  static const contactRequestCountDiameter = 20.0;
  static const contactRequestNotificationDotDiameter = 8.0;
  static const profileHeaderHeight = 48.0;
  static const profileAvatarRadius = 42.0;
  static const profileAvatarTextSize = 30.0;
  static const profilePhotoButtonHeight = 32.0;
  static const profilePhotoCropPreviewSize = 260.0;
  static const profilePhotoCropOutputSize = 512;
  static const profileRowHeight = 54.0;
  static const profileBackdropBlur = 3.0;
  static const messageHistoryHorizontalInset = 20.0;
  static const messageAvatarDiameter = 40.0;
  static const messageAvatarGap = 4.0;
  static const messageAvatarSlotWidth = 44.0;
  static const messageBubbleMaxWidth = 520.0;
  static const messageBubbleHorizontalInset = 20.0;
  static const messageBubbleVerticalInset = 12.0;
  static const messageReplyAccentWidth = 2.0;
  static const messageReplyTextInset = 8.0;
  static const messageReplyContentGap = 7.0;
  static const messageReplyLineGap = 1.0;
  static const messageReplyTitleSize = 11.0;
  static const messageReplyBodySize = 12.0;
  static const messageTranslationProgressSize = 12.0;
  static const messageTranslationStatusIconSize = 14.0;
  static const messageTranslationDialogWidth = 264.0;
  static const messageTranslationDialogMaxHeight = 320.0;
  static const messageTranslationSearchHeight = 34.0;
  static const messageTranslationRowHeight = 38.0;
  static const messageTranslationEmptyHeight = 88.0;
  static const messageTranslationSearchIconSize = 16.0;
  static const messageTranslationCheckIconSize = 16.0;
  static const messageMenuWidth = 156.0;
  static const messageMenuVerticalInset = 4.0;
  static const messageMenuItemHeight = 34.0;
  static const messageMenuHorizontalInset = 10.0;
  static const messageMenuIconSize = 15.0;
  static const messageMenuItemGap = 8.0;
  static const messageMenuTextSize = 13.0;
  static const messageMenuSettingsDiameter = 22.0;
  static const messageMenuSettingsIconSize = 13.0;
  static const statusIconSize = 20.0;
}

abstract final class RetroColors {
  static const canvasTop = Color(0xFFF8FAFF);
  static const canvasBottom = Color(0xFFEFF4FB);
  static const glass = Color(0xCCFFFFFF);
  static const glassStrong = Color(0xEAFBFCFF);
  static const glassMuted = Color(0xB8F3F6FB);
  static const hairline = Color(0xFFDDE3EC);
  static const primary = Color(0xFF2F6FE4);
  static const primaryLight = Color(0xFFEAF2FF);
  static const primarySoft = Color(0x1F2F6FE4);
  static const ink = Color(0xFF17191C);
  static const mutedInk = Color(0xFF69707A);
}

abstract final class RetroTheme {
  static const _canvas = RetroColors.canvasBottom;
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceMuted = Color(0xFFF1F4F8);
  static const _surfaceSelected = RetroColors.primaryLight;
  static const _ink = RetroColors.ink;
  static const _mutedInk = RetroColors.mutedInk;
  static const _primary = RetroColors.primary;
  static const _primaryDark = Color(0xFF2457B6);
  static const _danger = Color(0xFFC9342F);
  static const _dangerLight = Color(0xFFFCE8E7);
  static const _divider = RetroColors.hairline;

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
