import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../models/user.dart';

class ConnectionCard extends StatelessWidget {
  final ConnectionModel connection;
  final String currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;

  const ConnectionCard({
    super.key,
    required this.connection,
    required this.currentUserId,
    this.onAccept,
    this.onReject,
    this.onRevoke,
  });

  UserModel get otherUser {
    return connection.requester.id == currentUserId ? connection.recipient : connection.requester;
  }

  bool get isRecipient => connection.recipient.id == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF8C00).withOpacity(0.2),
          child: Text(otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFFFF8C00))),
        ),
        title: Text(otherUser.name),
        subtitle: Text('@${otherUser.username}'),
        trailing: _buildActions(context),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (connection.status == 'pending' && isRecipient) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: onAccept),
          IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: onReject),
        ],
      );
    }
    if (connection.status == 'accepted') {
      return TextButton(onPressed: onRevoke, child: const Text('Revoke', style: TextStyle(color: Colors.red)));
    }
    return Text(connection.status, style: const TextStyle(color: Colors.grey));
  }
}
