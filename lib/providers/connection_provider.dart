import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'auth_provider.dart';

class ConnectionState {
  final List<ConnectionModel> connections;
  final bool isLoading;
  final String? error;

  ConnectionState({this.connections = const [], this.isLoading = false, this.error});

  List<ConnectionModel> get accepted => connections.where((c) => c.status == 'accepted').toList();
  List<ConnectionModel> get pending => connections.where((c) => c.status == 'pending').toList();
}

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final ApiService _api;

  ConnectionNotifier(this._api) : super(ConnectionState());

  Future<void> loadConnections() async {
    state = ConnectionState(isLoading: true);
    try {
      final data = await _api.getList(ApiConfig.connections);
      final connections = data.map((json) => ConnectionModel.fromJson(json)).toList();
      state = ConnectionState(connections: connections);
    } catch (e) {
      state = ConnectionState(error: e.toString());
    }
  }

  Future<bool> sendRequest(String username) async {
    try {
      await _api.post(ApiConfig.connectionRequest, {'recipientUsername': username});
      await loadConnections();
      return true;
    } catch (e) {
      state = ConnectionState(connections: state.connections, error: e.toString());
      return false;
    }
  }

  Future<void> accept(String id) async {
    await _api.post('${ApiConfig.connections}/$id/accept', {});
    await loadConnections();
  }

  Future<void> reject(String id) async {
    await _api.post('${ApiConfig.connections}/$id/reject', {});
    await loadConnections();
  }

  Future<void> revoke(String id) async {
    await _api.post('${ApiConfig.connections}/$id/revoke', {});
    await loadConnections();
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier(ref.read(apiServiceProvider));
});
