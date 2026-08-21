import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connection_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/connection_card.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(connectionProvider.notifier).loadConnections());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;
    final success = await ref.read(connectionProvider.notifier).sendRequest(username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Request sent!' : ref.read(connectionProvider).error ?? 'Failed')),
      );
      if (success) _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(connectionProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: 'Enter username to connect', prefixIcon: Icon(Icons.search)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_add, color: Color(0xFFFF8C00)),
                  onPressed: _sendRequest,
                ),
              ],
            ),
          ),
          Expanded(
            child: connState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : connState.connections.isEmpty
                    ? const Center(child: Text('No connections yet'))
                    : ListView(
                        children: [
                          if (connState.pending.isNotEmpty) ...[
                            const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            ...connState.pending.map((c) => ConnectionCard(
                              connection: c,
                              currentUserId: currentUserId,
                              onAccept: () => ref.read(connectionProvider.notifier).accept(c.id),
                              onReject: () => ref.read(connectionProvider.notifier).reject(c.id),
                            )),
                          ],
                          if (connState.accepted.isNotEmpty) ...[
                            const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Connected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            ...connState.accepted.map((c) => ConnectionCard(
                              connection: c,
                              currentUserId: currentUserId,
                              onRevoke: () => ref.read(connectionProvider.notifier).revoke(c.id),
                            )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
