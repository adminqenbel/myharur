import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;

  const AuthState({this.token, this.user, this.isLoading = false});

  bool get isLoggedIn => token != null;
  bool get isSetupComplete => user?['is_setup_complete'] == true;
  bool get isAdmin => ['Admin', 'Super Admin'].contains(user?['role']?['name']);
  bool get isSuperAdmin => user?['role']?['name'] == 'Super Admin';
  String? get uid => user?['uid'];
  String? get email => user?['email'];
  String? get loginProvider => user?['login_provider'];

  AuthState copyWith({String? token, Map<String, dynamic>? user, bool? isLoading}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true));

  /// Try to restore session from SharedPreferences
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      state = const AuthState();
      return;
    }
    ApiClient.setToken(token);
    try {
      final response = await ApiClient.dio.get('/users/me');
      state = AuthState(token: token, user: response.data);
    } catch (e) {
      // Token invalid/expired — clear it
      await prefs.remove('auth_token');
      ApiClient.clearToken();
      state = const AuthState();
    }
  }

  /// Login with token + user data from server response
  Future<void> loginWithToken(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    ApiClient.setToken(token);
    state = AuthState(token: token, user: user);
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final response = await ApiClient.dio.get('/users/me');
      state = state.copyWith(user: response.data);
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiClient.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
