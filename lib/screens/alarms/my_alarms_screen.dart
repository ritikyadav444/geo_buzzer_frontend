import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              : RefreshIndicator(
                  onRefresh: () => ref.read(alarmProvider.notifier).loadMyAlarms(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: alarmState.myAlarms.length,
                    itemBuilder: (context, index) {
                      final alarm = alarmState.myAlarms[index];
                      return AlarmCard(
                        alarm: alarm,
                        onCancel: alarm.status == 'active' ? () => ref.read(alarmProvider.notifier).cancelAlarm(alarm.id) : null,
                      );
                    },
                  ),
                ),
    );
  }
}
