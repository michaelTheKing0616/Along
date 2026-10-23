import 'package:flutter/material.dart';

import 'palette.dart';

/// Five sizes. Weights are 400, 500, and 600.
/// Body line-height is 1.4. Display is tighter. Nothing is under 13.
/// Digits are tabular, including money.
abstract final class AlongType {
  static const fallback = ['Inter'];
  static const figures = [FontFeature.tabularFigures()];

  static TextStyle _style(
    AlongPalette palette, {
    required double size,
    required double height,
    required FontWeight weight,
    required double tracking,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: palette.fontFamily,
      fontFamilyFallback: fallback,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: tracking,
      fontFeatures: figures,
      color: color ?? palette.ink,
    );
  }

  /// Page title. 32 / 600.
  static TextStyle display(AlongPalette palette) {
    return _style(
      palette,
      size: 32,
      height: 1.15,
      weight: FontWeight.w600,
      tracking: -0.64,
    );
  }

  /// Same size as [title]. Kept so older call sites do not invent a sixth size.
  static TextStyle heading(AlongPalette palette) => title(palette);

  /// Section title. 20 / 600.
  static TextStyle title(AlongPalette palette) {
    return _style(
      palette,
      size: 20,
      height: 1.25,
      weight: FontWeight.w600,
      tracking: -0.2,
    );
  }

  /// Reading text. 16 / 400, line-height 1.4.
  static TextStyle body(AlongPalette palette) {
    return _style(
      palette,
      size: 16,
      height: 1.4,
      weight: FontWeight.w400,
      tracking: 0,
    );
  }

  /// Secondary sentence. Same size as body, darker than the old grey.
  static TextStyle bodyMuted(AlongPalette palette) {
    return body(palette).copyWith(color: palette.ink.withValues(alpha: 0.72));
  }

  /// Row label. 14 / 500.
  static TextStyle label(AlongPalette palette) {
    return _style(
      palette,
      size: 14,
      height: 1.35,
      weight: FontWeight.w500,
      tracking: 0,
    );
  }

  /// Alias of [caption]. Never under 13, and not a faint grey.
  static TextStyle meta(AlongPalette palette) => caption(palette);

  /// Smallest text. 13 / 400, ink, not grey-on-grey.
  static TextStyle caption(AlongPalette palette) {
    return _style(
      palette,
      size: 13,
      height: 1.35,
      weight: FontWeight.w400,
      tracking: 0.13,
    );
  }

  /// Button label. 16 / 600.
  static TextStyle button(AlongPalette palette) {
    return _style(
      palette,
      size: 16,
      height: 1.2,
      weight: FontWeight.w600,
      tracking: -0.16,
    );
  }

  /// Money and counts. 32 / 600, tabular.
  static TextStyle numeric(AlongPalette palette) {
    return _style(
      palette,
      size: 32,
      height: 1.15,
      weight: FontWeight.w600,
      tracking: -0.48,
    );
  }

  static TextTheme textTheme(AlongPalette palette) {
    return TextTheme(
      displayLarge: display(palette),
      headlineLarge: title(palette),
      headlineMedium: title(palette),
      titleMedium: title(palette),
      bodyLarge: body(palette),
      bodyMedium: body(palette),
      bodySmall: caption(palette),
      labelLarge: label(palette),
    );
  }
}
