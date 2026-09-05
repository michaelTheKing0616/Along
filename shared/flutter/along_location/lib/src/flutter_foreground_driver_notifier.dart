import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:along_location/src/presence_ping_service.dart';

/// Starts the platform foreground service with Along visibility copy (doc 07 §6).
class FlutterForegroundDriverNotifier implements DriverForegroundNotifier {
  static const notificationTitle = 'Along';
  static const notificationText = "Along — you're visible to riders";

  @override
  Future<void> startVisibleNotification() async {
    if (await FlutterForegroundTask.isRunningService) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'along_driver_presence',
        channelName: 'Along driver visibility',
        channelDescription: 'Shown while you are visible to riders',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.startService(
      serviceId: 2208,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  @override
  Future<void> stopVisibleNotification() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
