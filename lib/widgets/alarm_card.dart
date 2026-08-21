import 'package:flutter/material.dart';
import '../models/alarm.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback? onCancel;
  final bool showOwner;

  const AlarmCard({super.key, required this.alarm, this.onCancel, this.showOwner = false});

  Color get _statusColor {
    switch (alarm.status) {
      case 'active': return const Color(0xFFFF8C00);
      case 'triggered': return Colors.green;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_pin, color: Color(0xFFFF8C00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alarm.label.isNotEmpty ? alarm.label : '${alarm.location.lat.toStringAsFixed(4)}, ${alarm.location.lng.toStringAsFixed(4)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(alarm.status.toUpperCase(), style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Radius: ${alarm.location.radiusMeters.round()}m', style: const TextStyle(color: Colors.grey)),
            if (showOwner && alarm.owner != null)
              Text('Set by: ${alarm.owner!.name}', style: const TextStyle(color: Colors.grey)),
            if (!showOwner && alarm.targets.isNotEmpty)
              Text('Targets: ${alarm.targets.map((t) => t.name.isNotEmpty ? t.name : t.id).join(", ")}', style: const TextStyle(color: Colors.grey)),
            if (onCancel != null && alarm.status == 'active') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
