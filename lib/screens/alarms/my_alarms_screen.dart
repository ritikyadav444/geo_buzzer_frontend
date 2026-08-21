import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/alarm.dart';
import '../../providers/alarm_provider.dart';
import '../../widgets/alarm_card.dart';

class MyAlarmsScreen extends ConsumerStatefulWidget {
  const MyAlarmsScreen({super.key});

  @override
  ConsumerState<MyAlarmsScreen> createState() => _MyAlarmsScreenState();
}

class _MyAlarmsScreenState extends ConsumerState<MyAlarmsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(alarmProvider.notifier).loadMyAlarms());
  }

  Widget _buildAlarmsList(WidgetRef ref, AlarmState alarmState) {
    // Group alarms by sequenceGroup
    final grouped = <String?, List<AlarmModel>>{};
    for (final alarm in alarmState.myAlarms) {
      final key = alarm.sequenceGroup;
      grouped.putIfAbsent(key, () => []).add(alarm);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(alarmProvider.notifier).loadMyAlarms(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: grouped.entries.expand<Widget>((entry) {
          if (entry.key != null && entry.value.length > 1) {
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('Sequence Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[600])),
              ),
              ...entry.value.map((alarm) => AlarmCard(
                alarm: alarm,
                onCancel: alarm.status == 'active' ? () => ref.read(alarmProvider.notifier).cancelAlarm(alarm.id) : null,
              )),
              const Divider(),
            ];
          }
          return entry.value.map((alarm) => AlarmCard(
            alarm: alarm,
            onCancel: alarm.status == 'active' ? () => ref.read(alarmProvider.notifier).cancelAlarm(alarm.id) : null,
          )).toList();
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarmState = ref.watch(alarmProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Alarms')),
      body: alarmState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alarmState.myAlarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No alarms yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const Text('Tap on the map to set one!', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : _buildAlarmsList(ref, alarmState),
    );
  }
}
