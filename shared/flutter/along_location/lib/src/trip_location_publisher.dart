import 'dart:async';

import 'package:along_location/src/location_sample.dart';
import 'package:along_location/src/location_stream.dart';

/// One GPS point batched for `trip_location_sample`.
typedef TripLocationPoint = ({
  String ts,
  double lat,
  double lng,
  double accuracyM,
  double? speedMps,
  double? heading,
});

typedef TripLocationSampleCallback = Future<void> Function({
  required String tripId,
  required List<TripLocationPoint> points,
});

/// Batches GPS samples and publishes via `trip_location_sample` during active trips.
class TripLocationPublisher {
  TripLocationPublisher({
    required LocationStreamSource locationSource,
    required this.onSample,
  }) : _locationSource = locationSource;

  final LocationStreamSource _locationSource;
  final TripLocationSampleCallback onSample;

  StreamSubscription<LocationSample>? _locationSub;
  Timer? _flushTimer;
  Duration _interval = const Duration(seconds: 5);
  final List<LocationSample> _buffer = [];
  String? _tripId;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start({
    required String tripId,
    required Duration sampleInterval,
  }) async {
    await stop();
    _tripId = tripId;
    _interval = sampleInterval;
    _running = true;

    final granted = await _locationSource.ensurePermission();
    if (!granted) {
      _running = false;
      return;
    }

    _locationSub = FilteredLocationStream(_locationSource)
        .track(minInterval: const Duration(seconds: 2))
        .listen(_bufferSample);

    _scheduleFlush();
  }

  Future<void> stop() async {
    _running = false;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _locationSub?.cancel();
    _locationSub = null;
    _buffer.clear();
    _tripId = null;
  }

  void _bufferSample(LocationSample sample) {
    if (!_running) return;
    _buffer.add(sample);
    if (_buffer.length > 5) {
      _buffer.removeAt(0);
    }
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    if (!_running) return;
    _flushTimer = Timer(_interval, () {
      unawaited(_flush());
      _scheduleFlush();
    });
  }

  Future<void> _flush() async {
    final tripId = _tripId;
    if (!_running || tripId == null || _buffer.isEmpty) return;

    final points = _buffer
        .map(
          (sample) => (
            ts: sample.recordedAt.toUtc().toIso8601String(),
            lat: sample.point.lat,
            lng: sample.point.lng,
            accuracyM: sample.accuracyM,
            speedMps: sample.speedMps,
            heading: sample.headingDegrees,
          ),
        )
        .toList(growable: false);
    _buffer.clear();

    await onSample(tripId: tripId, points: points);
  }
}
