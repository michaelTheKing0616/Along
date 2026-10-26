import 'dart:math';

import 'package:along_core/along_core.dart';
import 'package:test/test.dart';

const secret = '3f9a1c0d5e7b2a4c6e8f0a1b3c5d7e9f01234567';

/// Simulates a camera sampling the rider's screen: [samplesPerFrame] samples
/// per colour frame, optional RGB jitter, dropped samples and 1-sample glitches.
List<int> capture(
  List<int> frames, {
  int loops = 2,
  int samplesPerFrame = 3,
  int jitter = 0,
  double dropRate = 0,
  double glitchRate = 0,
  int seed = 7,
}) {
  final rnd = Random(seed);
  int noisy(int rgb) {
    int ch(int v) =>
        (v + (jitter == 0 ? 0 : rnd.nextInt(jitter * 2 + 1) - jitter)).clamp(
          0,
          255,
        );
    return (ch((rgb >> 16) & 0xFF) << 16) |
        (ch((rgb >> 8) & 0xFF) << 8) |
        ch(rgb & 0xFF);
  }

  final out = <int>[];
  for (var l = 0; l < loops; l++) {
    for (final f in frames) {
      for (var i = 0; i < samplesPerFrame; i++) {
        if (rnd.nextDouble() < dropRate) continue;
        if (rnd.nextDouble() < glitchRate) {
          out.add(0x000000 | rnd.nextInt(0xFFFFFF));
          continue;
        }
        out.add(noisy(f));
      }
    }
  }
  return out;
}

NaMeOpticalProof? decode(List<int> samples, DateTime now) {
  final d = NaMeOpticalDecoder();
  for (final s in samples) {
    final p = d.add(s, now);
    if (p != null) return p;
  }
  return null;
}

void main() {
  final riderNow = DateTime.utc(2026, 10, 26, 8, 30, 4);
  final step = NaMeOptical.stepAt(riderNow);

  test('code matches the server derivation (HMAC-SHA256, first two bytes)', () {
    // Same value as select _na_me_optical_code(secret, step) in migration 101.
    // Values taken from Postgres; if either changes, client and server disagree.
    expect(NaMeOptical.code(secret, 1000), 64207);
    expect(NaMeOptical.code(secret, 177645000), 7932);
  });

  test('no two consecutive frames share a colour', () {
    final f = NaMeOptical.frames(secret, step);
    expect(f.length, NaMeOptical.framesPerLoop);
    for (var i = 1; i < f.length; i++) {
      expect(f[i], isNot(f[i - 1]));
    }
  });

  test('round trip: clean frames decode to the exact code and step', () {
    final proof = decode(capture(NaMeOptical.frames(secret, step)), riderNow);
    expect(
      proof,
      NaMeOpticalProof(code: NaMeOptical.code(secret, step), step: step),
    );
  });

  test('every code value round-trips', () {
    for (var code = 0; code <= 0xFFFF; code += 251) {
      final proof = decode(
        capture(NaMeOptical.framesForCode(code, step)),
        riderNow,
      );
      expect(proof?.code, code, reason: 'code $code');
    }
  });

  test('clock skew: driver 60 s behind or 65 s ahead still resolves the rider step', () {
    final frames = NaMeOptical.frames(secret, step);
    for (final skew in [-60, -25, 0, 17, 65]) {
      final proof = decode(
        capture(frames),
        riderNow.add(Duration(seconds: skew)),
      );
      expect(proof?.step, step, reason: 'skew $skew s');
    }
  });

  test('noise: jitter, dropped samples and glitches still decode', () {
    final frames = NaMeOptical.frames(secret, step);
    final samples = capture(
      frames,
      loops: 3,
      samplesPerFrame: 4,
      jitter: 45,
      dropRate: 0.08,
      glitchRate: 0.05,
    );
    expect(decode(samples, riderNow)?.code, NaMeOptical.code(secret, step));
  });

  test('a partial loop decodes to nothing', () {
    final frames = NaMeOptical.frames(secret, step).sublist(0, 7);
    expect(decode(capture(frames, loops: 1), riderNow), isNull);
  });

  test('wrong code: a misread data frame fails the checksum or the transition rule', () {
    final frames = NaMeOptical.frames(secret, step);
    final corrupted = [...frames];
    final i = 3;
    corrupted[i] = NaMeOptical.palette.firstWhere(
      (c) => c != frames[i] && c != frames[i - 1] && c != frames[i + 1],
    );
    final proof = decode(capture(corrupted, loops: 1), riderNow);
    expect(
      proof == null || proof.code != NaMeOptical.code(secret, step),
      isTrue,
    );
  });

  test('another trip\'s secret never yields this trip\'s code', () {
    final other = NaMeOptical.frames(
      'ffffffffffffffffffffffffffffffffffffffff',
      step,
    );
    expect(
      decode(capture(other), riderNow)?.code,
      isNot(NaMeOptical.code(secret, step)),
    );
  });

  test('proof json is what confirm_na_me_match expects', () {
    expect(const NaMeOpticalProof(code: 42, step: 7).toJson(), {
      'method': 'optical',
      'code': 42,
      'step': 7,
    });
  });

  test('photosensitivity: white sync flashes under 3 per second', () {
    final frames = NaMeOptical.frames(secret, 1000);
    final syncs = frames.where((f) => f == NaMeOptical.sync).length;
    final loopSeconds = frames.length * NaMeOptical.frameMs / 1000;
    expect(syncs / loopSeconds, lessThan(3));
  });
}
