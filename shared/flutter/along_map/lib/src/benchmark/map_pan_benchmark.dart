import 'package:flutter/scheduler.dart';

/// Synthetic pan benchmark harness for map performance (doc 07 §12–§13).
///
/// Measurement method:
/// 1. Attach [MapPanBenchmark] to a [MapLibreMapController] on a reference device
///    (Tecno Spark 8C, 2 GB RAM — doc 07 §13).
/// 2. Call [startRecording], perform [stepCount] east-west camera pans via
///    [onPanStep], then [stopRecording].
/// 3. Frame timings are collected via [SchedulerBinding.addTimingsCallback].
/// 4. PASS when p95 frame build+raster time ≤ 16.7 ms (60 fps budget).
///
/// CI skips hardware runs; unit tests validate statistics on injected timings.
class MapPanBenchmark {
  MapPanBenchmark({
    this.targetP95Ms = 16.7,
    this.stepCount = 30,
  });

  final double targetP95Ms;
  final int stepCount;

  final List<Duration> _frameTimes = [];
  TimingsCallback? _callback;
  bool _recording = false;

  bool get isRecording => _recording;

  void startRecording() {
    if (_recording) return;
    _frameTimes.clear();
    _recording = true;
    _callback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        final total = timing.totalSpan;
        if (total > Duration.zero) {
          _frameTimes.add(total);
        }
      }
    };
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  MapPanBenchmarkResult stopRecording() {
    if (_callback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_callback!);
      _callback = null;
    }
    _recording = false;
    return MapPanBenchmarkResult.fromFrameTimes(
      List.unmodifiable(_frameTimes),
      targetP95Ms: targetP95Ms,
      stepCount: stepCount,
    );
  }

  /// Computes pan longitude offset for step [index] across [stepCount] steps.
  static double panLngOffset({
    required int index,
    required int stepCount,
    required double centerLng,
    required double spanDegrees,
  }) {
    if (stepCount <= 1) return centerLng;
    final t = index / (stepCount - 1);
    return centerLng + (t - 0.5) * spanDegrees;
  }
}

/// Aggregated frame timing result from a pan benchmark run.
class MapPanBenchmarkResult {
  MapPanBenchmarkResult({
    required this.frameCount,
    required this.p50Ms,
    required this.p95Ms,
    required this.maxMs,
    required this.targetP95Ms,
    required this.stepCount,
  });

  final int frameCount;
  final double p50Ms;
  final double p95Ms;
  final double maxMs;
  final double targetP95Ms;
  final int stepCount;

  bool get passesTarget => p95Ms <= targetP95Ms;

  factory MapPanBenchmarkResult.fromFrameTimes(
    List<Duration> frameTimes, {
    required double targetP95Ms,
    required int stepCount,
  }) {
    if (frameTimes.isEmpty) {
      return MapPanBenchmarkResult(
        frameCount: 0,
        p50Ms: double.infinity,
        p95Ms: double.infinity,
        maxMs: double.infinity,
        targetP95Ms: targetP95Ms,
        stepCount: stepCount,
      );
    }

    final sortedMs = frameTimes.map((d) => d.inMicroseconds / 1000.0).toList()
      ..sort();
    return MapPanBenchmarkResult(
      frameCount: sortedMs.length,
      p50Ms: _percentile(sortedMs, 0.50),
      p95Ms: _percentile(sortedMs, 0.95),
      maxMs: sortedMs.last,
      targetP95Ms: targetP95Ms,
      stepCount: stepCount,
    );
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return double.infinity;
    final index = (sorted.length * p).ceil().clamp(1, sorted.length) - 1;
    return sorted[index];
  }

  @override
  String toString() =>
      'MapPanBenchmarkResult(frames=$frameCount, p50=${p50Ms.toStringAsFixed(1)}ms, '
      'p95=${p95Ms.toStringAsFixed(1)}ms, max=${maxMs.toStringAsFixed(1)}ms, '
      'target=${targetP95Ms}ms, pass=$passesTarget)';
}

/// Reference device identifier for benchmark reports (doc 07 §13).
abstract final class MapReferenceDevice {
  static const name = 'Tecno Spark 8C';
  static const ramGb = 2;
  static const targetFps = 60;
  static const frameBudgetMs = 1000.0 / targetFps;
}
