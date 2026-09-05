/// Battery level for presence ping interval guard (doc 07 §6).
abstract class BatteryMonitor {
  Future<BatterySnapshot> read();
}

class BatterySnapshot {
  const BatterySnapshot({
    required this.levelPercent,
    required this.isCharging,
  });

  final int levelPercent;
  final bool isCharging;
}

/// Test double with fixed battery state.
class FakeBatteryMonitor implements BatteryMonitor {
  FakeBatteryMonitor(this.snapshot);

  BatterySnapshot snapshot;

  @override
  Future<BatterySnapshot> read() async => snapshot;
}
