import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic colour roles for Along.
///
/// Light is warm paper and warm ink, never pure grey or pure black.
/// Dark climbs in surface steps from the same hue. It is not an inversion.
/// Yellow is the only accent, under a tenth of any screen.
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
    bg: Color(0xFFF6F4F1),
    surface: Color(0xFFFBF9F6),
    recessed: Color(0xFFEFEBE6),
    ink: Color(0xFF141210),
    onInk: Color(0xFFFBF9F6),
    muted: Color(0xFF3A342C),
    line: Color(0xFF6E675F),
    accent: Color(0xFFF7D117),
    accentInk: Color(0xFF141210),
    danger: Color(0xFFB23A2F),
    dangerOn: Color(0xFFFBF9F6),
    success: Color(0xFF1C6B3C),
    mapLand: Color(0xFFE6E7EA),
    mapWater: Color(0xFFD4E2EE),
    mapPark: Color(0xFFE4EEE4),
    mapRoad: Color(0xFFFFFFFF),
    fontFamily: 'Geist',
  );

  static const dark = AlongPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF100F0D),
    surface: Color(0xFF26231F),
    recessed: Color(0xFF1A1815),
    ink: Color(0xFFF3EEE8),
    onInk: Color(0xFF100F0D),
    muted: Color(0xFFE4DCD2),
    line: Color(0xFF9A9188),
    accent: Color(0xFFF7D117),
    accentInk: Color(0xFF141210),
    danger: Color(0xFFF0A8A0),
    dangerOn: Color(0xFF100F0D),
    success: Color(0xFF8FCBAA),
    mapLand: Color(0xFF16171A),
    mapWater: Color(0xFF1A2A36),
    mapPark: Color(0xFF1A2620),
    mapRoad: Color(0xFFC9CCD2),
    fontFamily: 'Geist',
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

  /// Named roles. Map light and dark variants ride on the palette's map
  /// colours. A state still needs an icon and a word; these colours are
  /// not the whole signal.
  AlongRoles get roles => AlongRoles.of(this);

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

/// Semantic colours for the trip, the map, and status.
///
/// Light and dark each have a map variant ([mapLand], [mapWater], [mapPark],
/// [mapRoad]) taken from the palette so tiles and UI share one name.
@immutable
class AlongRoles {
  const AlongRoles({
    required this.route,
    required this.routeCasing,
    required this.pickup,
    required this.dropoff,
    required this.riderDot,
    required this.driverMarker,
    required this.stale,
    required this.success,
    required this.warn,
    required this.error,
    required this.mapLand,
    required this.mapWater,
    required this.mapPark,
    required this.mapRoad,
  });

  final Color route;
  final Color routeCasing;
  final Color pickup;
  final Color dropoff;
  final Color riderDot;
  final Color driverMarker;
  final Color stale;
  final Color success;
  final Color warn;
  final Color error;
  final Color mapLand;
  final Color mapWater;
  final Color mapPark;
  final Color mapRoad;

  static AlongRoles of(AlongPalette palette) {
    final dark = palette.brightness == Brightness.dark;
    return AlongRoles(
      route: palette.ink,
      routeCasing: palette.surface,
      pickup: palette.accent,
      dropoff: palette.ink,
      riderDot: palette.ink,
      driverMarker: palette.ink,
      stale: palette.muted,
      success: palette.success,
      warn: dark ? const Color(0xFFE7C98A) : const Color(0xFF7A4E16),
      error: palette.danger,
      mapLand: palette.mapLand,
      mapWater: palette.mapWater,
      mapPark: palette.mapPark,
      mapRoad: palette.mapRoad,
    );
  }
}
