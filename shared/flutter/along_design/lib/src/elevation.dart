import 'package:flutter/material.dart';

/// Elevation is a tinted shadow with a real offset. Cards use a border
/// instead. A surface never gets both. [jk-ui] [imp/craft-floor]
abstract final class AlongElevation {
  static List<BoxShadow> sheet(Color ink) {
    return [
      BoxShadow(
        color: ink.withValues(alpha: 0.10),
        offset: const Offset(0, -8),
        blurRadius: 24,
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
