import 'user.dart';

class ConnectionModel {
  final String id;
  final UserModel requester;
  final UserModel recipient;
  final String status;

  ConnectionModel({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      id: json['_id'] ?? '',
      requester: UserModel.fromJson(json['requester'] ?? {}),
      recipient: UserModel.fromJson(json['recipient'] ?? {}),
      status: json['status'] ?? 'pending',
    );
  }
}
