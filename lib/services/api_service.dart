import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }

  bool get hasTokens => _accessToken != null;

  String? get accessToken => _accessToken;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    var response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
          body: jsonEncode(body),
        );
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(data['error'] ?? 'Request failed', response.statusCode);
    }
    return data;
  }

  Future<List<dynamic>> getList(String path) async {
    var response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );

    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: _headers,
        );
      }
    }

    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body);
      throw ApiException(data['error'] ?? 'Request failed', response.statusCode);
    }
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<bool> _tryRefresh() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setTokens(data['accessToken'], data['refreshToken']);
        return true;
      }
    } catch (_) {}
    await clearTokens();
    return false;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
