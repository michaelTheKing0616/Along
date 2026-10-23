import 'package:flutter/material.dart';

import 'palette.dart';

/// Brand type. Geist (Vercel, SIL OFL) carries display and UI.
/// Inter is only the glyph fallback: Geist has no naira (U+20A6).
/// Tracking tightens as size grows and loosens at caption.
/// Every style turns tabular figures on, so digits share one width.
/// A screen uses two weights: regular and semibold.
/// [jk-typography] [imp/typeset]
abstract final class AlongType {
  static const fallback = ['Inter'];
  static const figures = [FontFeature.tabularFigures()];

  static TextStyle display(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 34,
      height: 1.05,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.36,
      fontFeatures: figures,
      color: palette.ink,
    );
  }

  static TextStyle heading(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 22,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.44,
      fontFeatures: figures,
      color: palette.ink,
    );
  }

  static TextStyle title(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.33,
      fontFeatures: figures,
      color: palette.ink,
    );
  }

  static TextStyle body(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 15,
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.09,
      fontFeatures: figures,
      color: palette.ink,
    );
  }

  static TextStyle bodyMuted(AlongPalette palette) {
    return body(palette).copyWith(color: palette.muted);
  }

  /// Secondary line under a name: 14sp, one step under body.
  static TextStyle meta(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.24,
      fontFeatures: figures,
      color: palette.muted,
    );
  }

  static TextStyle caption(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.24,
      fontFeatures: figures,
      color: palette.muted,
    );
  }

  static TextStyle button(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
      fontFeatures: figures,
      color: palette.onInk,
    );
  }

  static TextStyle numeric(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 32,
      height: 1.1,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.96,
      fontFeatures: figures,
      color: palette.ink,
    );
  }

  static TextTheme textTheme(AlongPalette palette) {
    return TextTheme(
      displayLarge: display(palette),
      headlineLarge: heading(palette),
      headlineMedium: title(palette),
      titleMedium: title(palette),
      bodyLarge: body(palette),
      bodyMedium: body(palette),
      bodySmall: bodyMuted(palette).copyWith(fontSize: 12, height: 1.3),
      labelLarge: button(palette).copyWith(color: palette.ink),
    );
  }
}
