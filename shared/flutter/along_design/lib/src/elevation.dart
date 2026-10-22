import 'package:flutter/material.dart';

/// Elevation is a tinted shadow with a real offset. Cards use a border
/// instead. A surface never gets both. [jk-ui] [imp/craft-floor]
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
}
