import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/alarm_card.dart';
import '../../widgets/connection_card.dart';

class IncomingScreen extends ConsumerStatefulWidget {
  const IncomingScreen({super.key});

  @override
  ConsumerState<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends ConsumerState<IncomingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(alarmProvider.notifier).loadTargetingMe();
      ref.read(connectionProvider.notifier).loadConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarmState = ref.watch(alarmProvider);
    final connState = ref.watch(connectionProvider);
    final currentUserId = ref.watch(authProvider).user?.id ?? '';

    final pendingRequests = connState.pending.where((c) => c.recipient.id == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(alarmProvider.notifier).loadTargetingMe();
          await ref.read(connectionProvider.notifier).loadConnections();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text('Alarms for you', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            if (alarmState.targetingMe.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('No active alarms targeting you', style: TextStyle(color: Colors.grey)))
            else
              ...alarmState.targetingMe.map((alarm) => AlarmCard(alarm: alarm, showOwner: true)),
            const Divider(height: 32),
            const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text('Connection Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            if (pendingRequests.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('No pending requests', style: TextStyle(color: Colors.grey)))
            else
              ...pendingRequests.map((c) => ConnectionCard(
                connection: c,
                currentUserId: currentUserId,
                onAccept: () => ref.read(connectionProvider.notifier).accept(c.id),
                onReject: () => ref.read(connectionProvider.notifier).reject(c.id),
              )),
          ],
        ),
      ),
    );
  }
}
