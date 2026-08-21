import 'user.dart';

class AlarmLocation {
  final double lat;
  final double lng;
  final double radiusMeters;

  AlarmLocation({required this.lat, required this.lng, this.radiusMeters = 150});

  factory AlarmLocation.fromJson(Map<String, dynamic> json) {
    return AlarmLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'radiusMeters': radiusMeters};
}

class AlarmModel {
  final String id;
  final UserModel? owner;
  final List<UserModel> targets;
  final AlarmLocation location;
  final String label;
  final String tune;
  final String status;
  final String? sequenceGroup;
  final int? sequenceOrder;

  AlarmModel({
    required this.id,
    this.owner,
    this.targets = const [],
    required this.location,
    this.label = '',
    this.tune = 'default',
    this.status = 'active',
    this.sequenceGroup,
    this.sequenceOrder,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['_id'] ?? '',
      owner: json['owner'] is Map ? UserModel.fromJson(json['owner']) : null,
      targets: json['targets'] is List
          ? (json['targets'] as List).map((t) => t is Map ? UserModel.fromJson(t as Map<String, dynamic>) : UserModel(id: t.toString(), name: '', username: '', email: '')).toList()
          : [],
      location: AlarmLocation.fromJson(json['location'] ?? {}),
      label: json['label'] ?? '',
      tune: json['tune'] ?? 'default',
      status: json['status'] ?? 'active',
      sequenceGroup: json['sequenceGroup'],
      sequenceOrder: json['sequenceOrder'],
    );
  }
}
