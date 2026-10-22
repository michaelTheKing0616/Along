import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic colour roles for Along.
///
/// Light is near-white surfaces and near-black ink. Dark is a deep neutral,
/// not a brown dusk. Yellow is the only accent, used for the live thing
/// (you, the seat, the selected ride), never as a wash behind a card.
/// [jk-colors] [taste]
@immutable
class AlongPalette extends ThemeExtension<AlongPalette> {
  const AlongPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.recessed,
    required this.ink,
    required this.onInk,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.danger,
    required this.dangerOn,
    required this.success,
    required this.mapLand,
    required this.mapWater,
    required this.mapPark,
    required this.mapRoad,
    required this.fontFamily,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color recessed;
  final Color ink;
  final Color onInk;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color danger;
  final Color dangerOn;
  final Color success;
  final Color mapLand;
  final Color mapWater;
  final Color mapPark;
  final Color mapRoad;
  final String fontFamily;

  static const light = AlongPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    recessed: Color(0xFFEEF0F3),
    ink: Color(0xFF111111),
    onInk: Color(0xFFFFFFFF),
    muted: Color(0xFF5C5C66),
    line: Color(0xFF6E6E76),
    accent: Color(0xFFF7D117),
    accentInk: Color(0xFF111111),
    danger: Color(0xFFB91C1C),
    dangerOn: Color(0xFFFFFFFF),
    success: Color(0xFF157A3A),
    mapLand: Color(0xFFF4F5F7),
    mapWater: Color(0xFFD5E3EE),
    mapPark: Color(0xFFE3EBE4),
    mapRoad: Color(0xFF8B9098),
    fontFamily: 'Satoshi',
  );

  static const dark = AlongPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0E10),
    surface: Color(0xFF1C1C1F),
    recessed: Color(0xFF121214),
    ink: Color(0xFFF5F5F7),
    onInk: Color(0xFF111111),
    muted: Color(0xFFA8A8B3),
    line: Color(0xFF8E8E98),
    accent: Color(0xFFF7D117),
    accentInk: Color(0xFF111111),
    danger: Color(0xFFF87171),
    dangerOn: Color(0xFF111111),
    success: Color(0xFF7DCEA0),
    mapLand: Color(0xFF0E0E10),
    mapWater: Color(0xFF1A2C36),
    mapPark: Color(0xFF1A2820),
    mapRoad: Color(0xFF5C6168),
    fontFamily: 'Satoshi',
  );

  /// Previous neutral system, kept so before/after gallery frames share a layout.
  static const legacy = AlongPalette(
    brightness: Brightness.light,
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    recessed: Color(0xFFF5F5F5),
    ink: Color(0xFF0A0A0A),
    onInk: Color(0xFFFFFFFF),
    muted: Color(0xFF6B6B6B),
    line: Color(0xFFE5E5E5),
    accent: Color(0xFFF7D117),
    accentInk: Color(0xFF0A0A0A),
    danger: Color(0xFFB91C1C),
    dangerOn: Color(0xFFFFFFFF),
    success: Color(0xFF15803D),
    mapLand: Color(0xFFF4F4F2),
    mapWater: Color(0xFFCFE3EA),
    mapPark: Color(0xFFE6EEE3),
    mapRoad: Color(0xFFD8D8D6),
    fontFamily: 'Inter',
  );

  static AlongPalette of(BuildContext context) {
    return Theme.of(context).extension<AlongPalette>() ?? light;
  }

  @override
  AlongPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? recessed,
    Color? ink,
    Color? onInk,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentInk,
    Color? danger,
    Color? dangerOn,
    Color? success,
    Color? mapLand,
    Color? mapWater,
    Color? mapPark,
    Color? mapRoad,
    String? fontFamily,
  }) {
    return AlongPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      recessed: recessed ?? this.recessed,
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      danger: danger ?? this.danger,
      dangerOn: dangerOn ?? this.dangerOn,
      success: success ?? this.success,
      mapLand: mapLand ?? this.mapLand,
      mapWater: mapWater ?? this.mapWater,
      mapPark: mapPark ?? this.mapPark,
      mapRoad: mapRoad ?? this.mapRoad,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  AlongPalette lerp(AlongPalette? other, double t) {
    if (other == null) return this;
    return AlongPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      recessed: Color.lerp(recessed, other.recessed, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerOn: Color.lerp(dangerOn, other.dangerOn, t)!,
      success: Color.lerp(success, other.success, t)!,
      mapLand: Color.lerp(mapLand, other.mapLand, t)!,
      mapWater: Color.lerp(mapWater, other.mapWater, t)!,
      mapPark: Color.lerp(mapPark, other.mapPark, t)!,
      mapRoad: Color.lerp(mapRoad, other.mapRoad, t)!,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
    );
  }

  /// WCAG contrast ratio. 1 is identical, 21 is black on white.
  static double contrast(Color a, Color b) {
    final hi = math.max(_lum(a), _lum(b));
    final lo = math.min(_lum(a), _lum(b));
    return (hi + 0.05) / (lo + 0.05);
  }

  static double _lum(Color color) {
    double channel(double value) {
      return value <= 0.04045
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }
}
