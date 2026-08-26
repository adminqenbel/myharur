import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../models/user_profile.dart';

// ==============================================================================
// AUTH SERVICE — QenBel Identity + MyHarur Profile
//
// Auth flow:
//   1. User signs in via Google OAuth (Android client ID) or Email/Pass (staff)
//   2. Supabase Auth (MyHarur DB) receives the JWT from QenBel identity
//   3. Profile row is auto-created via DB trigger (handle_new_myharur_user)
//   4. AuthService fetches profile + user_roles from MyHarur DB
//   5. onboarding_state determines which screen to show
// ==============================================================================

/// Google OAuth Android client ID
/// (configured in Supabase Auth > Providers > Google)
const String kAndroidOAuthClientId =
    '976428818123-tr1tgub2a690vh7g88s2icpq19smmuvv.apps.googleusercontent.com';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier instance = AuthNotifier._();
  AuthNotifier._();
  void notify() => notifyListeners();
}

class AuthService {
  static UserProfile _profile = UserProfile.guest;
  static bool _loggedIn = false;
  static StreamSubscription<AuthState>? _authSub;

  // ── Public getters ───────────────────────────────────────────────────────────

  static UserProfile get currentProfile => _profile;

  /// True only when a real non-guest user is logged in.
  /// BUG FIX: previous code had `|| _profile.roles.contains('guest')` which
  /// allowed the guest sentinel to count as authenticated.
  static bool get isAuthenticated => _loggedIn && !_profile.isGuest;

  static User? get currentUser => SupabaseConfig.client?.auth.currentUser;

  // ── Initialization ───────────────────────────────────────────────────────────

  static void init() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    // Check if already signed in (app resume)
    final initialUser = client.auth.currentUser;
    if (initialUser != null) {
      _loggedIn = true;
      _fetchProfile(initialUser.id);
    }

    // Listen for auth state changes
    _authSub = client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        _loggedIn = true;
        await _fetchProfile(session.user.id);
        AuthNotifier.instance.notify();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _loggedIn = false;
        _profile = UserProfile.guest;
        AuthNotifier.instance.notify();
      }
    });
  }

  static void dispose() {
    _authSub?.cancel();
  }

  // ── Sign In: Google OAuth ────────────────────────────────────────────────────

  /// Launches Google OAuth via external browser.
  /// Android deep-link: com.myharur.app://login-callback
  static Future<bool> signInWithGoogle() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      debugPrint('[AUTH] signInWithGoogle: Supabase not initialized');
      return false;
    }
    try {
      final launched = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.myharur.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('[AUTH] Google OAuth error: $e');
      return false;
    }
  }

  // ── Sign In: Email/Password (staff only) ─────────────────────────────────────

  static Future<bool> signInWithEmailPassword(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
      if (res.session != null) {
        _loggedIn = true;
        await _fetchProfile(res.user!.id);
        AuthNotifier.instance.notify();
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] Email sign-in error: $e');
    }
    return false;
  }

  // ── Sign Up: Email/Password (staff provisioning via admin) ───────────────────

  static Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      final res = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password.trim(),
        data: {'full_name': fullName.trim()},
      );
      if (res.user != null) {
        // Profile auto-created by DB trigger handle_new_myharur_user
        _loggedIn = true;
        await _fetchProfile(res.user!.id);
        AuthNotifier.instance.notify();
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] Sign-up error: $e');
    }
    return false;
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    _loggedIn = false;
    _profile = UserProfile.guest;
    await SupabaseConfig.client?.auth.signOut();
    AuthNotifier.instance.notify();
  }

  // ── Profile ──────────────────────────────────────────────────────────────────

  /// Save profile updates to MyHarur DB
  static Future<bool> saveProfile({
    required String fullName,
    required String phone,
    String? wardLocality,
    int? wardId,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bio,
    String? username,
    String? onboardingState,
    String? occupation,
  }) async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;

    try {
      await client.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        if (wardId != null) 'ward_id': wardId,
        if (wardLocality != null) 'ward_locality': wardLocality,
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone,
        if (bio != null) 'bio': bio,
        if (username != null) 'username': username,
        if (onboardingState != null) 'onboarding_state': onboardingState,
        if (occupation != null) 'occupation': occupation,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      _profile = _profile.copyWith(
        fullName: fullName,
        phone: phone,
        wardId: wardId,
        wardLocality: wardLocality,
        bloodGroup: bloodGroup,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        bio: bio,
        username: username,
        onboardingState: onboardingState,
        occupation: occupation,
      );
      AuthNotifier.instance.notify();
      return true;
    } catch (e) {
      debugPrint('[AUTH] saveProfile error: $e');
      return false;
    }
  }

  /// Advance onboarding to the next state
  static Future<void> advanceOnboarding(String newState) async {
    await saveProfile(
      fullName: _profile.fullName,
      phone: _profile.phone,
      onboardingState: newState,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Future<void> _fetchProfile(String userId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // Profile not yet created (trigger may not have run yet — wait briefly)
        await Future.delayed(const Duration(milliseconds: 800));
        final retry = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (retry != null) {
          await _buildProfileFromRow(userId, retry, client);
        }
        return;
      }
      await _buildProfileFromRow(userId, data, client);
    } catch (e) {
      debugPrint('[AUTH] _fetchProfile error: $e');
    }
  }

  static Future<void> _buildProfileFromRow(
    String userId,
    Map<String, dynamic> data,
    SupabaseClient client,
  ) async {
    // Fetch roles from user_roles join table
    List<String> roles = ['resident'];
    try {
      final roleRows = await client
          .from('user_roles')
          .select('role')
          .eq('uid', userId)
          .isFilter('revoked_at', null);
      roles = (roleRows as List)
          .map((r) => r['role'] as String)
          .toList();
      if (roles.isEmpty) roles = ['resident'];
    } catch (_) {}

    _profile = UserProfile.fromJson(data, roles: roles);
    debugPrint('[AUTH] Profile loaded: ${_profile.fullName} | state: ${_profile.onboardingState} | roles: $roles');
  }
}
