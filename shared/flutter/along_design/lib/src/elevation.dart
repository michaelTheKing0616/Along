import 'package:flutter/material.dart';

/// Two lifts, and a hairline everywhere else.
/// [rest] is a card that has to leave the page. [raised] is a sheet or the
/// GO control. Lists, rows, and grouped cards use [hairline].
abstract final class AlongElevation {
  static List<BoxShadow> rest(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.08),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }

  static List<BoxShadow> raised(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.16),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ];
  }

  static List<BoxShadow> sheet(Color ink) => raised(ink);

  static List<BoxShadow> float(Color ink) => rest(ink);

  static List<BoxShadow> card(Color ink) => rest(ink);

  static List<BoxShadow> lifted(Color ink) => rest(ink);

  static Border hairline(Color ink) {
    return Border.all(color: ink.withValues(alpha: 0.12));
  }
}
