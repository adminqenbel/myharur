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
  bool get isSuperAdmin => hasRole('Super Admin');
  bool get isModerator => hasRole('Moderator') || hasRole('Admin') || hasRole('Super Admin');
  
  bool get usernameRequired =>
      user?['username_required'] == true || (user?['username'] == null && user?['mid'] != null);
  String? get uid => user?['uid'];
  String? get mid => user?['mid'];
  String? get username => user?['username'];
  String? get displayName => user?['display_name'];
  String? get email => user?['email'];
  String? get loginProvider => user?['login_provider'];

  List<String> get permissions => List<String>.from(user?['permissions'] ?? []);
  List<String> get roles {
    final legacyRole = user?['role']?['name'];
    final multipleRoles = (user?['roles'] as List<dynamic>?)
        ?.map((r) => r['name'] as String)
        .toList() ?? [];
    if (legacyRole != null && !multipleRoles.contains(legacyRole)) {
      multipleRoles.add(legacyRole);
    }
    return multipleRoles;
  }

  bool hasPermission(String perm) => isSuperAdmin || permissions.contains(perm);
  bool hasRole(String roleName) => roles.contains(roleName);

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

  /// Guest Mode Login
  Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'guest_mode');
    ApiClient.setToken('guest_mode');
    state = const AuthState(token: 'guest_mode', user: {
      'uid': 'guest',
      'mid': 'GUEST',
      'username': 'guest',
      'display_name': 'Guest User',
      'role': {'name': 'Guest'},
      'is_setup_complete': true,
      'username_required': false,
    });
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final response = await ApiClient.dio.get('/users/me');
      state = state.copyWith(user: response.data);
    } catch (_) {}
  }

  /// Called after set-username to update token + user in place
  Future<void> setAuth(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    ApiClient.setToken(token);
    state = AuthState(token: token, user: user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ApiClient.clearToken();
    state = const AuthState();
  }

  Future<void> logoutAll() async {
    try {
      if (state.token != null && state.token != 'guest_mode') {
        await ApiClient.dio.post('/auth/logout-all');
      }
    } catch (_) {}
    await logout();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
