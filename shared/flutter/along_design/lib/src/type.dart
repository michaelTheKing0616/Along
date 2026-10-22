import 'package:flutter/material.dart';

import 'palette.dart';

/// Brand type. Geist (Vercel, SIL OFL) carries display and UI.
/// Inter is only the glyph fallback: Geist has no naira (U+20A6).
/// Display tracking is tighter than the body; 24sp and up sit slightly negative.
/// Fares and ETAs use [numeric], which turns on tabular figures.
/// [jk-typography] [imp/typeset]
abstract final class AlongType {
  static const fallback = ['Inter'];

  static TextStyle display(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 34,
      height: 1.05,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.53,
      color: palette.ink,
    );
  }

  static TextStyle heading(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 24,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
      color: palette.ink,
    );
  }

  static TextStyle title(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: palette.ink,
    );
  }

  static TextStyle body(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
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
      fontSize: 14,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: palette.muted,
    );
  }

  static TextStyle caption(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: palette.muted,
    );
  }

  static TextStyle button(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 17,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: palette.onInk,
    );
  }

  static TextStyle numeric(AlongPalette palette) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: 32,
      height: 1.1,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.96,
      fontFeatures: const [FontFeature.tabularFigures()],
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
      bodySmall: bodyMuted(palette).copyWith(fontSize: 14, height: 1.4),
      labelLarge: button(palette).copyWith(color: palette.ink),
    );
  }
}
