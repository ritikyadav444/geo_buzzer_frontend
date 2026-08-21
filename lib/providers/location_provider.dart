import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import '../services/location_service.dart';
import 'alarm_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final geofenceMonitorProvider = Provider<GeofenceMonitor>((ref) {
  return GeofenceMonitor(ref);
});

class GeofenceMonitor {
  final Ref _ref;
  Timer? _timer;
  final LocationService _locationService = LocationService();
  void Function(AlarmModel alarm)? onAlarmTriggered;

  GeofenceMonitor(this._ref);

  void start() {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    final alarms = _ref.read(alarmProvider).targetingMe;
    if (alarms.isEmpty) return;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    final triggered = _locationService.checkGeofences(alarms, position);
    for (final alarm in triggered) {
      await _ref.read(alarmProvider.notifier).triggerAlarm(alarm.id, position.latitude, position.longitude);
      onAlarmTriggered?.call(alarm);
    }
  }
}
