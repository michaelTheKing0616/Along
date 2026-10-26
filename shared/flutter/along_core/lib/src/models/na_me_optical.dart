import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Na Me optical sync (doc 07 §9): the rider's screen flashes a short colour
/// sequence that encodes a time-based code derived from the trip's handshake
/// secret; the driver's camera decodes it locally and submits it as proof.
///
/// Must stay byte-for-byte compatible with `_na_me_optical_code` in
/// migration 101: HMAC-SHA256(key: secret text, message: step as decimal),
/// first two bytes, big-endian.
abstract final class NaMeOptical {
  /// Seconds per code step.
  static const stepSeconds = 10;

  /// Frame duration on the rider's screen.
  static const frameMs = 160;

  /// Data symbols per sequence (2 bits each, 16-bit code).
  static const dataSymbols = 8;

  /// Sync + 8 data + checksum + 2 step-residue symbols (step mod 16).
  static const framesPerLoop = 1 + dataSymbols + 3;

  /// Signal palette, as RGB. Index 0..4 are data colours; [sync] is white.
  /// High-chroma primaries a phone camera separates even under glare.
  static const palette = <int>[
    0xFF2D2D,
    0x22D36B,
    0x2F6BFF,
    0xFFD21F,
    0xD63AF9,
  ];
  static const sync = 0xFFFFFF;

  static int stepAt(DateTime t) =>
      t.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ stepSeconds;

  static int code(String secret, int step) {
    final mac = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode('$step'));
    return (mac.bytes[0] << 8) | mac.bytes[1];
  }

  /// Colour frames for one loop: white sync, then each symbol is encoded
  /// differentially (`next = (prev + 1 + s) % 5`) so two frames in a row are
  /// never the same colour and the decoder needs no frame clock.
  static List<int> frames(String secret, int step) =>
      framesForCode(code(secret, step), step);

  static List<int> framesForCode(int code, int step) {
    final symbols = <int>[
      for (var i = dataSymbols - 1; i >= 0; i--) (code >> (i * 2)) & 3,
    ];
    final check = symbols.fold<int>(0, (a, s) => a + s) % 4;
    symbols
      ..add(check)
      ..add((step % 16) >> 2)
      ..add(step % 4);
    final out = <int>[sync];
    var prev = 0;
    for (final s in symbols) {
      prev = (prev + 1 + s) % 5;
      out.add(palette[prev]);
    }
    return out;
  }
}

/// A decoded proof, ready for `confirm_na_me_match`.
class NaMeOpticalProof {
  const NaMeOpticalProof({required this.code, required this.step});
  final int code;
  final int step;

  Map<String, dynamic> toJson() => {
    'method': 'optical',
    'code': code,
    'step': step,
  };

  @override
  bool operator ==(Object other) =>
      other is NaMeOpticalProof && other.code == code && other.step == step;

  @override
  int get hashCode => Object.hash(code, step);

  @override
  String toString() => 'NaMeOpticalProof($code @ $step)';
}

/// Streaming decoder. Feed it the average colour of the frame's centre region
/// at whatever rate the camera delivers; it classifies each sample, drops
/// glitches shorter than [minRun] samples, collapses runs, and returns a proof
/// once a full loop passes its checksum.
class NaMeOpticalDecoder {
  NaMeOpticalDecoder({this.minRun = 2, this.maxDistance = 140});

  /// Samples a colour must persist for to count (rejects 1-sample glitches).
  final int minRun;

  /// Max RGB distance from a palette colour; further samples are noise.
  final double maxDistance;

  final List<int> _symbols = <int>[];
  int? _runClass;
  int _runLength = 0;

  void reset() {
    _symbols.clear();
    _runClass = null;
    _runLength = 0;
  }

  /// -1 = sync, 0..4 = palette index, null = unclassifiable.
  int? classify(int rgb) {
    final candidates = <int>[NaMeOptical.sync, ...NaMeOptical.palette];
    var best = -2;
    var bestD = double.infinity;
    for (var i = 0; i < candidates.length; i++) {
      final d = _distance(rgb, candidates[i]);
      if (d < bestD) {
        bestD = d;
        best = i - 1;
      }
    }
    return bestD <= maxDistance ? best : null;
  }

  /// Adds one sample; returns a proof when a loop decodes, else null.
  /// [now] is the driver's clock, used to resolve the step from its residue.
  NaMeOpticalProof? add(int rgb, DateTime now) {
    final c = classify(rgb);
    if (c == _runClass) {
      _runLength++;
    } else {
      _runClass = c;
      _runLength = 1;
    }
    if (c == null || _runLength != minRun) return null;
    if (_symbols.isNotEmpty && _symbols.last == c) return null;
    _symbols.add(c);
    if (_symbols.length > NaMeOptical.framesPerLoop * 3) {
      _symbols.removeRange(0, _symbols.length - NaMeOptical.framesPerLoop * 3);
    }
    return _tryDecode(now);
  }

  NaMeOpticalProof? _tryDecode(DateTime now) {
    const n = NaMeOptical.framesPerLoop;
    for (var start = _symbols.length - n; start >= 0; start--) {
      if (_symbols[start] != -1) continue;
      final body = _symbols.sublist(start + 1, start + n);
      if (body.contains(-1)) continue;
      final decoded = decodeLoop(body, now);
      if (decoded != null) return decoded;
    }
    return null;
  }

  /// Decodes the 11 palette indices that follow a sync frame.
  static NaMeOpticalProof? decodeLoop(List<int> body, DateTime now) {
    if (body.length != NaMeOptical.framesPerLoop - 1) return null;
    final symbols = <int>[];
    var prev = 0;
    for (final c in body) {
      final s = (c - prev - 1) % 5;
      if (s > 3) return null; // impossible transition: misread frame
      symbols.add(s);
      prev = c;
    }
    final data = symbols.sublist(0, NaMeOptical.dataSymbols);
    final check = symbols[NaMeOptical.dataSymbols];
    final residue =
        (symbols[NaMeOptical.dataSymbols + 1] << 2) |
        symbols[NaMeOptical.dataSymbols + 2];
    if (data.fold<int>(0, (a, s) => a + s) % 4 != check) return null;
    final code = data.fold<int>(0, (a, s) => (a << 2) | s);
    return NaMeOpticalProof(code: code, step: resolveStep(residue, now));
  }

  /// The step nearest the driver's clock whose value mod 16 is [residue]:
  /// tolerates about ±70 s of clock skew between the two phones.
  static int resolveStep(int residue, DateTime now) {
    final local = NaMeOptical.stepAt(now);
    final delta = (residue - local) % 16;
    return delta <= 8 ? local + delta : local + delta - 16;
  }

  static double _distance(int a, int b) {
    final dr = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
    final dg = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF);
    final db = (a & 0xFF) - (b & 0xFF);
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }
}
