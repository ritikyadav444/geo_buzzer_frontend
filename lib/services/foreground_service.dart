import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'geobuzzer_tracking',
      channelName: 'GeoBuzzer Location Tracking',
      channelDescription: 'Keeps GPS active for geofence alarms',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}

Future<bool> requestPermissions() async {
  final notifPerm = await FlutterForegroundTask.checkNotificationPermission();
  if (notifPerm != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
  return true;
}

Future<void> startTracking() async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    serviceId: 256,
    notificationTitle: 'GeoBuzzer',
    notificationText: 'Location tracking active',
    callback: _startCallback,
  );
}

Future<void> stopTracking() async {
  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
