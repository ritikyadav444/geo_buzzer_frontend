import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool clearError = false, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(AuthState());

  Future<void> checkAuth() async {
    await _api.loadTokens();
    if (_api.hasTokens) {
      try {
        final data = await _api.get(ApiConfig.me);
        state = state.copyWith(user: UserModel.fromJson(data));
      } catch (_) {
        await _api.clearTokens();
      }
    }
  }

  Future<bool> signup(String name, String username, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.post(ApiConfig.signup, {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.post(ApiConfig.verifyOtp, {'email': email, 'otp': otp});
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.post(ApiConfig.login, {'email': email, 'password': password});
      await _api.setTokens(data['accessToken'], data['refreshToken']);
      final user = UserModel.fromJson(data['user']);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = AuthState();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
