import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/alarm.dart';
import '../services/location_service.dart';
import 'alarm_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final geofenceMonitorProvider = Provider<GeofenceMonitor>((ref) {
  return GeofenceMonitor(ref);
});

class GeofenceMonitor {
  final Ref _ref;
  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;
  final LocationService _locationService = LocationService();
  void Function(AlarmModel alarm)? onAlarmTriggered;
  final Set<String> _alreadyTriggered = {};

  GeofenceMonitor(this._ref);

  void start() {
    stop();
    _alreadyTriggered.clear();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _checkPosition(position);
    });

    _fallbackTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final position = await _locationService.getCurrentPosition();
      if (position != null) _checkPosition(position);
    });

    _locationService.getCurrentPosition().then((pos) {
      if (pos != null) _checkPosition(pos);
    });
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  void _checkPosition(Position position) {
    final alarms = _ref.read(alarmProvider).myAlarms
        .where((a) => a.status == 'active' && !_alreadyTriggered.contains(a.id))
        .toList();
    if (alarms.isEmpty) return;

    final triggered = _locationService.checkGeofences(alarms, position);
    for (final alarm in triggered) {
      _alreadyTriggered.add(alarm.id);
      _ref.read(alarmProvider.notifier).triggerAlarm(alarm.id, position.latitude, position.longitude);
      onAlarmTriggered?.call(alarm);
    }
  }
}
