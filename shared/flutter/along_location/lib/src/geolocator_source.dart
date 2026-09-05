import 'package:along_core/along_core.dart';
import 'package:along_location/src/location_sample.dart';
import 'package:along_location/src/location_stream.dart';
import 'package:geolocator/geolocator.dart';

/// Geolocator-backed location source for rider while-in-use (doc 07 §6).
class GeolocatorLocationSource implements LocationStreamSource {
  @override
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterM.round(),
      ),
    ).map(
      (position) => LocationSample(
        point: GeoPoint(
          lat: position.latitude,
          lng: position.longitude,
        ),
        accuracyM: position.accuracy,
        recordedAt: position.timestamp,
        headingDegrees: position.heading,
        speedMps: position.speed,
      ),
    );
  }
}

/// Test double with fixed permission and sample stream.
class FakeLocationStreamSource implements LocationStreamSource {
  FakeLocationStreamSource({
    this.permissionGranted = true,
    this.fixedSamples = const [],
  });

  final bool permissionGranted;
  final List<LocationSample> fixedSamples;

  @override
  Future<bool> ensurePermission() async => permissionGranted;

  @override
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  }) =>
      Stream.fromIterable(fixedSamples);
}
