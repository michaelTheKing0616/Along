import 'package:flutter/foundation.dart';

/// Outcome of comparing a scanned plate with the vehicle's registered plate.
enum PlateMatchKind { match, mismatch }

/// A Nigerian plate reduced to letters and digits, plus a display form.
class ParsedPlate {
  const ParsedPlate({required this.canonical, required this.display});

  /// No spaces or dashes. Letter slots use O/I, digit slots use 0/1.
  final String canonical;

  /// Canonical form with the usual hyphen, for example `ABC-123XY`.
  final String display;
}

class PlateJudgement {
  const PlateJudgement({
    required this.kind,
    required this.expectedCanonical,
    required this.seenCanonical,
    required this.distance,
  });

  final PlateMatchKind kind;
  final String expectedCanonical;
  final String seenCanonical;
  final int distance;
}

/// Remembers the match outcome only. Frames and files are never recorded.
class PlateScanLog {
  static String? last;

  static void record(PlateMatchKind kind) {
    last = kind.name;
    debugPrint('plate_scan result=${kind.name}');
  }
}

final _alnum = RegExp(r'[^A-Z0-9]');

/// Current private and commercial plates, then the older 2-3-3 layout,
/// then a 3-letter 4-digit commercial layout.
const _shapes = <List<bool>>[
  [true, true, true, false, false, false, true, true],
  [true, true, false, false, false, true, true, true],
  [true, true, true, false, false, false, false],
];

String compactPlate(String raw) {
  return raw.toUpperCase().replaceAll(_alnum, '');
}

/// Pulls every plate-shaped token out of an OCR blob.
List<ParsedPlate> extractNigerianPlates(String ocrText) {
  final compact = compactPlate(ocrText);
  final found = <String, ParsedPlate>{};
  for (final shape in _shapes) {
    final width = shape.length;
    if (compact.length < width) continue;
    for (var start = 0; start <= compact.length - width; start++) {
      final parsed = _parseWindow(
        compact.substring(start, start + width),
        shape,
      );
      if (parsed != null) found[parsed.canonical] = parsed;
    }
  }
  return found.values.toList(growable: false);
}

/// One plate string, already separated or not. Null when it is not a plate.
ParsedPlate? parseNigerianPlate(String raw) {
  final plates = extractNigerianPlates(raw);
  if (plates.isEmpty) return null;
  plates.sort((a, b) => b.canonical.length.compareTo(a.canonical.length));
  return plates.first;
}

/// Null while the frame has no plate-shaped text. A parsed plate that is
/// more than one edit from the registered plate is a mismatch.
PlateJudgement? judgePlateReading({
  required String ocrText,
  required String expectedPlate,
}) {
  final expected = parseNigerianPlate(expectedPlate);
  final expectedCanonical = expected?.canonical ?? compactPlate(expectedPlate);
  if (expectedCanonical.length < 5) return null;
  final seen = extractNigerianPlates(ocrText);
  if (seen.isEmpty) return null;

  ParsedPlate? best;
  var bestDistance = 1 << 20;
  for (final plate in seen) {
    final distance = _levenshtein(plate.canonical, expectedCanonical);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = plate;
    }
  }
  if (best == null) return null;
  return PlateJudgement(
    kind: bestDistance <= 1 ? PlateMatchKind.match : PlateMatchKind.mismatch,
    expectedCanonical: expectedCanonical,
    seenCanonical: best.canonical,
    distance: bestDistance,
  );
}

ParsedPlate? _parseWindow(String window, List<bool> letterSlot) {
  final chars = <String>[];
  for (var i = 0; i < window.length; i++) {
    final raw = window[i];
    final letter = letterSlot[i];
    if (letter) {
      if (!_isLetterSlot(raw)) return null;
      chars.add(
        raw == '0'
            ? 'O'
            : raw == '1'
            ? 'I'
            : raw,
      );
    } else {
      if (!_isDigitSlot(raw)) return null;
      chars.add(
        raw == 'O'
            ? '0'
            : raw == 'I'
            ? '1'
            : raw,
      );
    }
  }
  final canonical = chars.join();
  return ParsedPlate(
    canonical: canonical,
    display: _display(canonical, letterSlot),
  );
}

bool _isLetterSlot(String char) {
  final code = char.codeUnitAt(0);
  final letter = code >= 65 && code <= 90;
  return letter || char == '0' || char == '1';
}

bool _isDigitSlot(String char) {
  final code = char.codeUnitAt(0);
  final digit = code >= 48 && code <= 57;
  return digit || char == 'O' || char == 'I';
}

String _display(String canonical, List<bool> letterSlot) {
  if (letterSlot.length == 8 && letterSlot[2] && !letterSlot[3]) {
    return '${canonical.substring(0, 3)}-${canonical.substring(3)}';
  }
  if (letterSlot.length == 8 && !letterSlot[2]) {
    return '${canonical.substring(0, 2)}-${canonical.substring(2, 5)}-${canonical.substring(5)}';
  }
  if (letterSlot.length == 7) {
    return '${canonical.substring(0, 3)}-${canonical.substring(3)}';
  }
  return canonical;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      final insert = current[j] + 1;
      final delete = previous[j + 1] + 1;
      final replace = previous[j] + cost;
      var best = insert < delete ? insert : delete;
      if (replace < best) best = replace;
      current[j + 1] = best;
    }
    previous = current;
  }
  return previous[b.length];
}
