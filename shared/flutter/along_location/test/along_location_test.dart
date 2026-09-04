import 'package:along_core/along_core.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LocationSample boarding quality threshold', () {
    final sample = LocationSample(
      point: const GeoPoint(lat: 9, lng: 7),
      accuracyM: 40,
      recordedAt: DateTime.utc(2026, 1, 1),
    );
    expect(sample.isBoardingQuality, isTrue);
  });

  test('FilteredLocationStream drops high-accuracy samples', () async {
    final source = _FakeLocationSource([
      LocationSample(
        point: const GeoPoint(lat: 1, lng: 2),
        accuracyM: 600,
        recordedAt: DateTime.utc(2026, 1, 1),
      ),
      LocationSample(
        point: const GeoPoint(lat: 1, lng: 2),
        accuracyM: 20,
        recordedAt: DateTime.utc(2026, 1, 1, 0, 0, 5),
      ),
    ]);
    final stream = FilteredLocationStream(source);
    final samples = await stream.track(minInterval: Duration.zero).take(2).toList();
    expect(samples, hasLength(1));
    expect(samples.first.accuracyM, 20);
  });
}

class _FakeLocationSource implements LocationStreamSource {
  _FakeLocationSource(this._samples);

  final List<LocationSample> _samples;

  @override
  Stream<LocationSample> samples({
    required double distanceFilterM,
    required double maxAccuracyM,
  }) async* {
    yield* Stream.fromIterable(_samples);
  }

  @override
  Future<bool> ensurePermission() async => true;
}
