import 'package:along_location/src/battery_monitor.dart';
import 'package:battery_plus/battery_plus.dart';

/// Reads device battery via battery_plus.
class DeviceBatteryMonitor implements BatteryMonitor {
  DeviceBatteryMonitor({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  @override
  Future<BatterySnapshot> read() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    return BatterySnapshot(
      levelPercent: level,
      isCharging: state == BatteryState.charging ||
          state == BatteryState.full,
    );
  }
}
