import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paper and dusk text pairs clear WCAG AA', () {
    void pair(Color fg, Color bg, {double min = 4.5}) {
      expect(AlongPalette.contrast(fg, bg), greaterThanOrEqualTo(min));
    }

    for (final palette in [AlongPalette.light, AlongPalette.dark]) {
      pair(palette.ink, palette.bg);
      pair(palette.ink, palette.surface);
      pair(palette.muted, palette.bg);
      pair(palette.muted, palette.surface);
      pair(palette.accentInk, palette.accent);
      pair(palette.dangerOn, palette.danger);
      pair(palette.onInk, palette.ink);
      pair(palette.line, palette.bg, min: 3);
      pair(palette.line, palette.surface, min: 3);
    }
  });

  test('sheet spring is visually at rest within 300ms', () {
    final simulation = SpringSimulation(AlongSprings.sheet, 0, 1, 0);
    expect((simulation.x(0.22) - 1).abs(), lessThan(0.02));
  });
}
