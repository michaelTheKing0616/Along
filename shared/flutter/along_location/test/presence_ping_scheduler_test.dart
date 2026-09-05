import 'package:along_core/along_core.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('battery guard doubles ping interval', () async {
    final battery = FakeBatteryMonitor(
      const BatterySnapshot(levelPercent: 10, isCharging: false),
    );
    final location = FakeLocationStreamSource(
      permissionGranted: true,
      fixedSamples: [
        LocationSample(
          point: const GeoPoint(lat: 9.05, lng: 7.49),
          accuracyM: 10,
          recordedAt: DateTime.utc(2026, 9, 5),
          headingDegrees: 90,
          speedMps: 0,
        ),
      ],
    );

    final scheduler = PresencePingScheduler(
      locationSource: location,
      batteryMonitor: battery,
      batteryGuardPercent: 15,
      onPing: (_) async {},
    );

    await scheduler.start(
      movingInterval: const Duration(milliseconds: 200),
      stillInterval: const Duration(milliseconds: 200),
      seatsAvailable: 4,
    );

    expect(scheduler.batteryGuardActive, isTrue);
    expect(scheduler.effectiveInterval, const Duration(milliseconds: 400));

    await scheduler.stop();
  });
}
