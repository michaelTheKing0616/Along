import 'package:flutter/material.dart';

/// Elevation is a tinted shadow with a real offset. Cards are borderless
/// and sit on a layered shadow. A selected card may add an accent outline
/// on top of that lift. [jk-ui] [imp/craft-floor]
abstract final class AlongElevation {
  static List<BoxShadow> sheet(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.16),
        offset: const Offset(0, -10),
        blurRadius: 28,
      ),
      BoxShadow(
        color: ink.withValues(alpha: 0.06),
        offset: const Offset(0, -1),
        blurRadius: 4,
      ),
    ];
  }

  static List<BoxShadow> float(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.14),
        offset: const Offset(0, 6),
        blurRadius: 16,
      ),
    ];
  }

  /// Quiet card on a near-white sheet. Two layers so the edge still reads.
  static List<BoxShadow> card(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.05),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: ink.withValues(alpha: 0.08),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ];
  }

  /// Selected card. One tight shadow so it does not paint a second card.
  static List<BoxShadow> lifted(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.12),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }
}
