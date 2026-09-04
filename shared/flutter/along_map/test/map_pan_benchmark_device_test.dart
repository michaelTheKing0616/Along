import 'package:along_map/along_map.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hardware benchmark — skipped in CI (doc 07 §13).
///
/// Run on reference device:
/// ```bash
/// flutter test test/map_pan_benchmark_device_test.dart \
///   --device-id=<tecno-spark-8c>
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'records frame timings during synthetic pan',
    () {
    final benchmark = MapPanBenchmark(stepCount: 30);
    benchmark.startRecording();

    for (var i = 0; i < 30; i++) {
      MapPanBenchmark.panLngOffset(
        index: i,
        stepCount: 30,
        centerLng: AbujaMapConstants.centerLng,
        spanDegrees: 0.15,
      );
    }

    SchedulerBinding.instance.scheduleFrame();
    final result = benchmark.stopRecording();

    expect(result.frameCount, greaterThanOrEqualTo(0));
    // Hardware gate: p95 ≤ 16.7 ms on reference device.
    expect(
      result.passesTarget,
      isTrue,
      reason: 'Expected 60 fps pan on ${MapReferenceDevice.name}',
    );
  },
    skip: 'Requires reference device hardware (Tecno Spark 8C)',
  );
}
