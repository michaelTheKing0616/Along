import 'package:flutter/material.dart';

/// Each lift is a tight contact shadow plus a soft ambient one.
/// Both are warm and low. Hairlines are half a logical pixel.
abstract final class AlongElevation {
  static List<BoxShadow> rest(Color ink) => _pair(ink, 0.07, 0.05, 1, 10, 18);

  static List<BoxShadow> raised(Color ink) => _pair(ink, 0.09, 0.07, 1, 16, 28);

  static List<BoxShadow> sheet(Color ink) => raised(ink);

  static List<BoxShadow> float(Color ink) => rest(ink);

  static List<BoxShadow> card(Color ink) => rest(ink);

  static List<BoxShadow> lifted(Color ink) => rest(ink);

  static Border hairline(Color ink) {
    return Border.all(color: ink.withValues(alpha: 0.14), width: 0.5);
  }

  static List<BoxShadow> _pair(
    Color ink,
    double contact,
    double ambient,
    double contactY,
    double ambientY,
    double ambientBlur,
  ) {
    final warm = Color.alphaBlend(
      const Color(0xFF8A5A32).withValues(alpha: 0.45),
      ink,
    );
    return [
      BoxShadow(
        color: warm.withValues(alpha: contact),
        offset: Offset(0, contactY),
        blurRadius: 1.5,
      ),
      BoxShadow(
        color: warm.withValues(alpha: ambient),
        offset: Offset(0, ambientY),
        blurRadius: ambientBlur,
      ),
    ];
  }
}
