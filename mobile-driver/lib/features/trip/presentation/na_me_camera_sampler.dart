import 'dart:typed_data';

/// Average RGB of the centre square of a camera frame: the rider's colour
/// panel sits inside the reticle there. Pure so it runs in tests with
/// synthetic frames; the screen feeds it `CameraImage` planes.
abstract final class NaMeCameraSampler {
  /// Fraction of the shorter side the sampled square covers.
  static const centreFraction = 0.18;

  /// YUV420 (Android). [uvPixelStride] is 1 for I420, 2 for NV21-style.
  static int centreRgbYuv({
    required Uint8List y,
    required Uint8List u,
    required Uint8List v,
    required int width,
    required int height,
    required int yRowStride,
    required int uvRowStride,
    required int uvPixelStride,
  }) {
    final (x0, y0, x1, y1) = _box(width, height);
    var r = 0, g = 0, b = 0, n = 0;
    for (var py = y0; py < y1; py += 2) {
      for (var px = x0; px < x1; px += 2) {
        final yy = y[py * yRowStride + px];
        final uvIndex = (py >> 1) * uvRowStride + (px >> 1) * uvPixelStride;
        final uu = u[uvIndex] - 128;
        final vv = v[uvIndex] - 128;
        r += _clamp(yy + 1.402 * vv);
        g += _clamp(yy - 0.344136 * uu - 0.714136 * vv);
        b += _clamp(yy + 1.772 * uu);
        n++;
      }
    }
    return _pack(r, g, b, n);
  }

  /// BGRA8888 (iOS).
  static int centreRgbBgra({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rowStride,
  }) {
    final (x0, y0, x1, y1) = _box(width, height);
    var r = 0, g = 0, b = 0, n = 0;
    for (var py = y0; py < y1; py += 2) {
      for (var px = x0; px < x1; px += 2) {
        final i = py * rowStride + px * 4;
        b += bytes[i];
        g += bytes[i + 1];
        r += bytes[i + 2];
        n++;
      }
    }
    return _pack(r, g, b, n);
  }

  /// Camera auto-exposure washes saturated colours toward grey; stretch
  /// each sample so its brightest channel reaches full scale.
  static int normalise(int rgb) {
    final r = (rgb >> 16) & 0xFF, g = (rgb >> 8) & 0xFF, b = rgb & 0xFF;
    final hi = [r, g, b].reduce((a, c) => a > c ? a : c);
    final lo = [r, g, b].reduce((a, c) => a < c ? a : c);
    if (hi < 40) return 0x000000;
    // Near-neutral and bright: the white sync frame.
    if (hi - lo < 40) return hi > 150 ? 0xFFFFFF : rgb;
    int s(int c) => ((c - lo) * 255 ~/ (hi - lo)).clamp(0, 255);
    return (s(r) << 16) | (s(g) << 8) | s(b);
  }

  static (int, int, int, int) _box(int w, int h) {
    final side = ((w < h ? w : h) * centreFraction).round();
    final x0 = (w - side) ~/ 2, y0 = (h - side) ~/ 2;
    return (x0, y0, x0 + side, y0 + side);
  }

  static int _clamp(num v) => v.round().clamp(0, 255);

  static int _pack(int r, int g, int b, int n) {
    if (n == 0) return 0;
    return ((r ~/ n) << 16) | ((g ~/ n) << 8) | (b ~/ n);
  }
}
