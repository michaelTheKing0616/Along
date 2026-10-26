import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_camera_sampler.dart';

void main() {
  test('BGRA centre sample ignores the edges', () {
    const w = 20, h = 20;
    final px = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        final centre = (x - 10).abs() < 4 && (y - 10).abs() < 4;
        px[i] = centre ? 200 : 0; // B
        px[i + 1] = 0;
        px[i + 2] = centre ? 20 : 255; // R
        px[i + 3] = 255;
      }
    }
    final rgb = NaMeCameraSampler.centreRgbBgra(
      bytes: px,
      width: w,
      height: h,
      rowStride: w * 4,
    );
    expect(rgb & 0xFF, 200);
    expect((rgb >> 16) & 0xFF, 20);
  });

  test('YUV grey centre decodes to grey', () {
    const w = 16, h = 16;
    final y = Uint8List(w * h)..fillRange(0, w * h, 128);
    final uv = Uint8List(w * h ~/ 4)..fillRange(0, w * h ~/ 4, 128);
    final rgb = NaMeCameraSampler.centreRgbYuv(
      y: y,
      u: uv,
      v: uv,
      width: w,
      height: h,
      yRowStride: w,
      uvRowStride: w ~/ 2,
      uvPixelStride: 1,
    );
    expect((rgb >> 16) & 0xFF, closeTo(128, 2));
    expect(rgb & 0xFF, closeTo(128, 2));
  });

  test('normalise stretches washed colour, keeps white and dark', () {
    expect(NaMeCameraSampler.normalise(0xB07070), 0xFF0000);
    expect(NaMeCameraSampler.normalise(0xE0E0E0), 0xFFFFFF);
    expect(NaMeCameraSampler.normalise(0x101010), 0x000000);
  });
}
