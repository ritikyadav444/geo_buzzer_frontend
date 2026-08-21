class TriggerLogModel {
  final String id;
  final String alarmId;
  final String triggeredBy;
  final double lat;
  final double lng;
  final DateTime timestamp;

  TriggerLogModel({
    required this.id,
    required this.alarmId,
    required this.triggeredBy,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory TriggerLogModel.fromJson(Map<String, dynamic> json) {
    return TriggerLogModel(
      id: json['_id'] ?? '',
      alarmId: json['alarmId'] ?? '',
      triggeredBy: json['triggeredBy'] ?? '',
      lat: (json['location']?['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['location']?['lng'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
