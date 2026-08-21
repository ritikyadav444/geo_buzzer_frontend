import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alarm.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'auth_provider.dart';

class AlarmState {
  final List<AlarmModel> myAlarms;
  final List<AlarmModel> targetingMe;
  final bool isLoading;
  final String? error;

  AlarmState({this.myAlarms = const [], this.targetingMe = const [], this.isLoading = false, this.error});
}

class AlarmNotifier extends StateNotifier<AlarmState> {
  final ApiService _api;

  AlarmNotifier(this._api) : super(AlarmState());

  Future<void> loadMyAlarms() async {
    state = AlarmState(myAlarms: state.myAlarms, targetingMe: state.targetingMe, isLoading: true);
    try {
      final data = await _api.getList(ApiConfig.myAlarms);
      final alarms = data.map((json) => AlarmModel.fromJson(json)).toList();
      state = AlarmState(myAlarms: alarms, targetingMe: state.targetingMe);
    } catch (e) {
      state = AlarmState(myAlarms: state.myAlarms, targetingMe: state.targetingMe, error: e.toString());
    }
  }

  Future<void> loadTargetingMe() async {
    try {
      final data = await _api.getList(ApiConfig.targetingMe);
      final alarms = data.map((json) => AlarmModel.fromJson(json)).toList();
      state = AlarmState(myAlarms: state.myAlarms, targetingMe: alarms);
    } catch (e) {
      state = AlarmState(myAlarms: state.myAlarms, targetingMe: state.targetingMe, error: e.toString());
    }
  }

  Future<bool> createAlarm({
    required List<String> targetIds,
    required double lat,
    required double lng,
    double radiusMeters = 150,
    String label = '',
    String tune = 'default',
    String? sequenceGroup,
    int? sequenceOrder,
  }) async {
    try {
      await _api.post(ApiConfig.alarms, {
        'targets': targetIds,
        'location': {'lat': lat, 'lng': lng, 'radiusMeters': radiusMeters},
        'label': label,
        'tune': tune,
        if (sequenceGroup != null) 'sequenceGroup': sequenceGroup,
        if (sequenceOrder != null) 'sequenceOrder': sequenceOrder,
      });
      await loadMyAlarms();
      return true;
    } catch (e) {
      state = AlarmState(myAlarms: state.myAlarms, targetingMe: state.targetingMe, error: e.toString());
      return false;
    }
  }

  Future<bool> createSequenceGroup({
    required List<Map<String, dynamic>> alarmDefs,
  }) async {
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    for (int i = 0; i < alarmDefs.length; i++) {
      final def = alarmDefs[i];
      final success = await createAlarm(
        targetIds: List<String>.from(def['targetIds']),
        lat: def['lat'] as double,
        lng: def['lng'] as double,
        radiusMeters: (def['radiusMeters'] as num?)?.toDouble() ?? 150,
        label: def['label'] as String? ?? '',
        sequenceGroup: groupId,
        sequenceOrder: i,
      );
      if (!success) return false;
    }
    return true;
  }

  Future<void> cancelAlarm(String id) async {
    await _api.post('${ApiConfig.alarms}/$id/cancel', {});
    await loadMyAlarms();
  }

  Future<void> triggerAlarm(String id, double lat, double lng) async {
    await _api.post('${ApiConfig.alarms}/$id/trigger', {'location': {'lat': lat, 'lng': lng}});
    await loadTargetingMe();
  }
}

final alarmProvider = StateNotifierProvider<AlarmNotifier, AlarmState>((ref) {
  return AlarmNotifier(ref.read(apiServiceProvider));
});
