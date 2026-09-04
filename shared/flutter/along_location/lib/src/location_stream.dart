import 'package:along_location/src/location_sample.dart';

/// Abstraction over Geolocator (rider while-in-use / driver foreground service).
abstract class LocationStreamSource {
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  });

  Future<bool> ensurePermission();
}

/// Throttles samples by movement and drops poor-accuracy fixes.
class FilteredLocationStream {
  FilteredLocationStream(this._source);

  final LocationStreamSource _source;

  Stream<LocationSample> track({
    double distanceFilterM = 5,
    double maxAccuracyM = 500,
    Duration minInterval = const Duration(seconds: 3),
  }) async* {
    DateTime? lastEmit;
    await for (final sample in _source.samples(
      distanceFilterM: distanceFilterM,
      maxAccuracyM: maxAccuracyM,
    )) {
      if (sample.accuracyM > maxAccuracyM) continue;
      if (lastEmit != null &&
          sample.recordedAt.difference(lastEmit!) < minInterval) {
        continue;
      }
      lastEmit = sample.recordedAt;
      yield sample;
    }
  }
}
