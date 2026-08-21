import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/alarm.dart';

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  List<AlarmModel> checkGeofences(List<AlarmModel> alarms, Position position) {
    final triggered = <AlarmModel>[];
    for (final alarm in alarms) {
      final distance = _haversineDistance(
        position.latitude, position.longitude,
        alarm.location.lat, alarm.location.lng,
      );
      if (distance <= alarm.location.radiusMeters) {
        triggered.add(alarm);
      }
    }
    return triggered;
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
