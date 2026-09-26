import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_store.dart';
import 'error_reporter.dart';
import 'push_service.dart';
import 'supabase_config.dart';
import '../models/place.dart';
import '../models/user_profile.dart';
import '../util/secure_log.dart';

// ==============================================================================
// AUTH SERVICE
//
//   • Residents sign in with Google (browser OAuth, deep link com.myharur.app://login-callback).
//   • Staff (moderator / admin / super admin) ALSO sign in with Google first, then add a
//     password in Account > Security. Google and email/password then log into the same user.
//   • Public email sign-up is disabled in the database; there is no sign-up in the app.
//   • The profile row is created by a DB trigger (name + Google photo copied from the token).
// ==============================================================================

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier instance = AuthNotifier._();
  AuthNotifier._();
  void notify() => notifyListeners();
}

class AuthService {
  static UserProfile _profile = UserProfile.guest;
  static bool _loggedIn = false;
  static StreamSubscription<AuthState>? _authSub;

  static final Completer<void> _ready = Completer<void>();
  static bool _initCalled = false;

  /// Completes once a saved session (if any) has been restored and its profile loaded, so the
  /// splash can hand over straight to the right screen instead of flashing the sign-in page.
  static Future<void> get ready => _initCalled ? _ready.future : Future<void>.value();

  /// Postgres error code of the last failed [saveProfile] (e.g. '23505' = duplicate username).
  static String? lastSaveErrorCode;

  /// Message of the last failed [saveProfile] (e.g. username_reserved), for friendly errors.
  static String? lastSaveErrorMessage;

  // ── Public getters ───────────────────────────────────────────────────────────

  static UserProfile get currentProfile => _profile;

  /// True only when a real (non-guest) user is signed in.
  static bool get isAuthenticated => _loggedIn && !_profile.isGuest;

  static User? get currentUser => SupabaseConfig.client?.auth.currentUser;

  static Map<String, dynamic> get _meta => currentUser?.userMetadata ?? const {};

  /// Google profile photo (from the OAuth token), falling back to what we stored.
  static String? get avatarUrl {
    final fromGoogle = (_meta['avatar_url'] ?? _meta['picture']) as String?;
    final stored = _profile.avatarUrl;
    return (stored != null && stored.isNotEmpty) ? stored : fromGoogle;
  }

  static String? get googleName => (_meta['full_name'] ?? _meta['name']) as String?;

  static bool get hasGoogleIdentity => currentUser?.identities?.any((i) => i.provider == 'google') ?? false;
  static bool get hasPasswordLogin => currentUser?.identities?.any((i) => i.provider == 'email') ?? false;

  /// Test hook: lets widget tests drive the profile without a Supabase session.
  @visibleForTesting
  static void debugSetProfile(UserProfile profile, {bool loggedIn = true}) {
    _profile = profile;
    _loggedIn = loggedIn;
    AuthNotifier.instance.notify();
  }

  // ── Initialization ───────────────────────────────────────────────────────────

  static void init() {
    _initCalled = true;
    unawaited(AccountStore.load());
    final client = SupabaseConfig.client;
    if (client == null) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }

    final initialUser = client.auth.currentUser;
    if (initialUser != null) {
      _loggedIn = true;
      _fetchProfile(initialUser.id).whenComplete(() {
        AuthNotifier.instance.notify();
        if (!_ready.isCompleted) _ready.complete();
      });
    } else if (!_ready.isCompleted) {
      _ready.complete();
    }

    _authSub = client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        _loggedIn = true;
        clearFailure();
        unawaited(AccountStore.updateToken(session.user.id, session.refreshToken ?? ''));
        // A token refresh or MFA upgrade changes nothing in the profile. Reloading on those events
        // made a loop: profile load -> listFactors -> token refresh -> event -> profile load ...
        final sameUser = _profile.id == session.user.id;
        if (sameUser && data.event != AuthChangeEvent.signedIn && data.event != AuthChangeEvent.initialSession) {
          AuthNotifier.instance.notify();
          return;
        }
        await _fetchProfile(session.user.id);
        AuthNotifier.instance.notify();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _loggedIn = false;
        _profile = UserProfile.guest;
        mfa.value = MfaStatus.unknown;
        AuthNotifier.instance.notify();
      }
    }, onError: (Object e) {
      // e.g. the OAuth redirect came back with an error, or the code exchange failed
      secureLog('[AUTH] auth stream error: $e');
      reportFailure(AuthFailureReason.failed);
    });
  }

  static void dispose() => _authSub?.cancel();

  // ── Sign in ──────────────────────────────────────────────────────────────────

  static Future<bool> signInWithGoogle() async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.myharur.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      secureLog('[AUTH] Google OAuth error: $e');
      return false;
    }
  }

  /// Email + password, for staff who have set a password (see [setStaffPassword]).
  static Future<bool> signInWithEmailPassword(String email, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      final res = await client.auth.signInWithPassword(email: email.trim().toLowerCase(), password: password);
      if (res.session != null) {
        _loggedIn = true;
        await _fetchProfile(res.user!.id);
        AuthNotifier.instance.notify();
        return true;
      }
    } catch (e) {
      secureLog('[AUTH] Email sign-in error: $e');
    }
    return false;
  }

  /// Adds (or changes) the email/password login on the CURRENT user, so a staff member who
  /// signed in with Google can later sign in either way. Does not create a new account.
  static Future<bool> setStaffPassword(String password) async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.auth.updateUser(UserAttributes(password: password));
      if (_profile.mustChangePassword) {
        await client.rpc('clear_must_change_password');
        _profile = _profile.copyWith(mustChangePassword: false);
      }
      await client.auth.refreshSession(); // pick up the new email identity
      AuthNotifier.instance.notify();
      return true;
    } catch (e) {
      secureLog('[AUTH] setStaffPassword error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    final leaving = _profile.id;
    await PushService.unregisterThisDevice().timeout(const Duration(seconds: 4), onTimeout: () {}); // this phone stops getting this account's notifications
    _loggedIn = false;
    _profile = UserProfile.guest;
    mfa.value = MfaStatus.unknown;
    try {
      await SupabaseConfig.client?.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    await AccountStore.remove(leaving);
    AuthNotifier.instance.notify();
    // Another account is saved on this phone: continue as that one instead of showing sign-in.
    for (final a in AccountStore.accounts.value) {
      if (await switchTo(a.id)) break;
    }
  }

  // ── Switch account ───────────────────────────────────────────────────────────

  /// Signs in as another saved account. Returns false (and forgets that account) when its saved
  /// session has expired or was revoked, so the person signs in again for that one.
  static Future<bool> switchTo(String id) async {
    final client = SupabaseConfig.client;
    if (client == null || !AccountStore.supported) return false;
    await AccountStore.load();
    final matches = AccountStore.accounts.value.where((a) => a.id == id);
    if (matches.isEmpty) return false;
    if (_profile.id == id) return true;
    try {
      mfa.value = MfaStatus.unknown;
      await client.auth.setSession(matches.first.refreshToken); // the auth-state listener loads the profile
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (_profile.id != id && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_profile.id != id) return false;
      AppErrors.restart(); // fresh screens: nothing from the previous account stays on display
      return true;
    } on AuthException catch (e) {
      secureLog('[AUTH] switch failed: ${e.statusCode}');
      await AccountStore.remove(id);
      return false;
    } catch (e) {
      secureLog('[AUTH] switch error: $e');
      return false;
    }
  }

  // ── Sign-in failures (drive the "couldn't sign you in" page) ────────────────

  /// Why the last sign-in attempt failed, or null. The shell shows AuthFailurePage while this is set.
  static final ValueNotifier<AuthFailureReason?> failure = ValueNotifier<AuthFailureReason?>(null);

  static void reportFailure(AuthFailureReason reason) {
    secureLog('[AUTH] sign-in failure: ${reason.name}');
    failure.value = reason;
  }

  static void clearFailure() => failure.value = null;

  // ── Username + password (a shortcut for accounts created with Google) ───────

  /// Seconds to wait when the last attempt was throttled.
  static int lastRetryAfterSeconds = 0;

  /// Set when username sign-in answers "paused": until when (null = until a super admin recovers it).
  static DateTime? lockedUntil;
  static bool lockedPermanently = false;

  static Future<UsernameLoginResult> signInWithUsername(String username, String password) async {
    final client = SupabaseConfig.client;
    if (client == null) return UsernameLoginResult.error;
    lastRetryAfterSeconds = 0;
    lockedUntil = null;
    lockedPermanently = false;
    try {
      final res = await http
          .post(
            Uri.parse('${SupabaseConfig.url}/functions/v1/username-login'),
            headers: {'Content-Type': 'application/json', 'apikey': SupabaseConfig.publishableKey},
            body: jsonEncode({'username': username.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 429) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        lastRetryAfterSeconds = (body['retry_after'] as num?)?.toInt() ?? 60;
        return UsernameLoginResult.tooManyAttempts;
      }
      if (res.statusCode == 423) {
        // password sign-in is paused (5 wrong tries = 24 h) or switched off until a super admin recovers it
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        lockedPermanently = body['permanent'] == true;
        lockedUntil = DateTime.tryParse(body['until'] as String? ?? '')?.toLocal();
        return UsernameLoginResult.locked;
      }
      if (res.statusCode == 401) return UsernameLoginResult.invalid;
      if (res.statusCode != 200) return UsernameLoginResult.error;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final refresh = body['refresh_token'] as String?;
      if (refresh == null) return UsernameLoginResult.error;
      await client.auth.setSession(refresh); // the auth-state listener loads the profile
      return UsernameLoginResult.ok;
    } on TimeoutException {
      return UsernameLoginResult.network;
    } on http.ClientException {
      return UsernameLoginResult.network;
    } catch (e) {
      secureLog('[AUTH] username sign-in error: $e');
      return UsernameLoginResult.error;
    }
  }

  /// Adds or changes the password on the CURRENT user (never creates an account). With it the person
  /// can sign in with @username + password as well as Google.
  static Future<bool> setPassword(String password) async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.auth.updateUser(UserAttributes(password: password));
      await client.auth.refreshSession();
      AuthNotifier.instance.notify();
      return true;
    } catch (e) {
      secureLog('[AUTH] setPassword error: $e');
      return false;
    }
  }

  /// Passwords: at least 10 characters, letters and digits, and not containing the username.
  static bool isStrongPassword(String password, {String? username}) {
    if (password.length < 10 || password.length > 128) return false;
    if (!RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) return false;
    final u = (username ?? '').replaceAll('@', '').toLowerCase();
    if (u.length >= 3 && password.toLowerCase().contains(u)) return false;
    return true;
  }

  // ── Two-factor (TOTP authenticator app) ─────────────────────────────────────

  /// Where the signed-in user stands with two-factor.
  static final ValueNotifier<MfaStatus> mfa = ValueNotifier<MfaStatus>(MfaStatus.unknown);

  static Future<void> refreshMfa() async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) {
      mfa.value = MfaStatus.unknown;
      return;
    }
    try {
      final aal = client.auth.mfa.getAuthenticatorAssuranceLevel();
      final factors = await client.auth.mfa.listFactors();
      final hasVerified = factors.totp.isNotEmpty;
      if (!hasVerified) {
        mfa.value = MfaStatus.notEnrolled;
      } else if (aal.currentLevel == AuthenticatorAssuranceLevels.aal2) {
        mfa.value = MfaStatus.satisfied;
      } else {
        mfa.value = MfaStatus.needsChallenge;
      }
    } catch (e) {
      secureLog('[AUTH] refreshMfa error: $e');
    }
  }

  /// Starts enrolment: returns the factor id, the otpauth:// URI (for the QR code) and the secret.
  static Future<MfaEnrollment?>? _enrolling;

  static Future<MfaEnrollment?> startMfaEnrollment() => _enrolling ??= _startMfaEnrollment().whenComplete(() => _enrolling = null);

  static Future<MfaEnrollment?> _startMfaEnrollment() async {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      // Remove leftover unverified attempts first, so a retry never fails on a duplicate name.
      final existing = await client.auth.mfa.listFactors();
      for (final f in existing.all.where((f) => f.status == FactorStatus.unverified)) {
        await client.auth.mfa.unenroll(f.id);
      }
      final res = await client.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'MyHarur', friendlyName: 'MyHarur');
      final totp = res.totp;
      if (totp == null) return null;
      return MfaEnrollment(factorId: res.id, uri: totp.uri, secret: totp.secret);
    } catch (e) {
      secureLog('[AUTH] startMfaEnrollment error: $e');
      return null;
    }
  }

  /// Verifies a 6-digit code for enrolment or for signing in. Upgrades the session to AAL2.
  static Future<bool> verifyMfaCode(String factorId, String code) async {
    final client = SupabaseConfig.client;
    if (client == null) return false;
    try {
      await client.auth.mfa.challengeAndVerify(factorId: factorId, code: code.trim());
      await refreshMfa();
      AuthNotifier.instance.notify();
      return true;
    } catch (_) {
      secureLog('[AUTH] verifyMfaCode failed');
      return false;
    }
  }

  /// The verified factor to challenge at sign-in.
  static Future<String?> verifiedFactorId() async {
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      final factors = await client.auth.mfa.listFactors();
      return factors.totp.isEmpty ? null : factors.totp.first.id;
    } catch (_) {
      return null;
    }
  }

  // ── Delete account (Google Play requirement) ────────────────────────────────

  /// Permanently deletes the login, profile and roles via delete_my_account().
  /// Alerts already published stay up but are no longer linked to the user.
  static Future<bool> deleteAccount() async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.rpc('delete_my_account');
    } catch (e) {
      secureLog('[AUTH] deleteAccount error: $e');
      return false;
    }
    final gone = _profile.id;
    _loggedIn = false;
    _profile = UserProfile.guest;
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
    await AccountStore.remove(gone);
    AuthNotifier.instance.notify();
    return true;
  }

  // ── Profile ──────────────────────────────────────────────────────────────────

  /// Re-reads the profile and roles (e.g. after an admin changes this user's role).
  static Future<void> refreshProfile() async {
    final id = currentUser?.id;
    if (id == null) return;
    await _fetchProfile(id);
    AuthNotifier.instance.notify();
  }

  static Future<bool> saveProfile({
    String? fullName,
    String? phone,
    PickedLocation? address,
    bool clearAddress = false,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? username,
    String? onboardingState,
    String? occupation,
  }) async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return false;
    lastSaveErrorCode = null;
    lastSaveErrorMessage = null;

    try {
      await client.from('profiles').update({
        if (fullName != null) 'full_name': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (address != null && !address.isEmpty) ...address.toColumns('address'),
        if (clearAddress || (address != null && address.isEmpty))
          ...const {'address_text': null, 'address_lat': null, 'address_lng': null, 'address_source': null},
        if (bloodGroup != null) 'blood_group': bloodGroup,
        if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName.trim(),
        if (emergencyContactPhone != null) 'emergency_contact_phone': emergencyContactPhone.trim(),
        if (username != null) 'username': username,
        if (onboardingState != null) 'onboarding_state': onboardingState,
        if (occupation != null) 'occupation': occupation,
      }).eq('id', user.id);

      _profile = _profile.copyWith(
        fullName: fullName?.trim(),
        phone: phone?.trim(),
        address: address != null && !address.isEmpty ? address : null,
        clearAddress: clearAddress || (address != null && address.isEmpty),
        bloodGroup: bloodGroup,
        emergencyContactName: emergencyContactName?.trim(),
        emergencyContactPhone: emergencyContactPhone?.trim(),
        username: username,
        onboardingState: onboardingState,
        occupation: occupation,
      );
      AuthNotifier.instance.notify();
      return true;
    } on PostgrestException catch (e) {
      lastSaveErrorCode = e.code;
      lastSaveErrorMessage = e.message;
      secureLog('[AUTH] saveProfile error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      secureLog('[AUTH] saveProfile error: $e');
      return false;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Future<void> _fetchProfile(String userId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    // Right after sign-in Supabase can briefly answer 401 "JWT issued at future" (PGRST303): the
    // token was minted a few milliseconds ahead of the API's clock. It clears on its own, so retry.
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        var data = await client.from('profiles').select().eq('id', userId).maybeSingle();
        if (data == null) {
          // The signup trigger may not have committed yet — wait briefly and retry once.
          await Future.delayed(const Duration(milliseconds: 800));
          data = await client.from('profiles').select().eq('id', userId).maybeSingle();
        }
        if (data != null) await _buildProfileFromRow(userId, data, client);
        return;
      } on PostgrestException catch (e) {
        final transient = e.code == 'PGRST303' || e.code == '401' || e.message.contains('JWT issued at future');
        if (!transient || attempt == 3) {
          secureLog('[AUTH] _fetchProfile error: ${e.code} ${e.message}');
          return;
        }
        await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
      } catch (e) {
        secureLog('[AUTH] _fetchProfile error: $e');
        return;
      }
    }
  }

  static Future<void> _buildProfileFromRow(String userId, Map<String, dynamic> data, SupabaseClient client) async {
    var roles = <String>['resident'];
    try {
      final rows = await client.from('user_roles').select('role').eq('uid', userId).isFilter('revoked_at', null);
      roles = (rows as List).map((r) => r['role'] as String).toList();
      if (roles.isEmpty) roles = ['resident'];
    } catch (_) {}

    _profile = UserProfile.fromJson(data, roles: roles);
    final rt = client.auth.currentSession?.refreshToken;
    if (rt != null && rt.isNotEmpty) {
      unawaited(AccountStore.remember(SavedAccount(
        id: _profile.id,
        name: _profile.fullName,
        username: _profile.username,
        avatarUrl: _profile.avatarUrl,
        refreshToken: rt,
      )));
    }
    unawaited(refreshMfa());
    if (_profile.isOnboardingComplete) unawaited(PushService.syncOnSignIn());
    secureLog('[AUTH] Profile loaded | state: ${_profile.onboardingState} | roles: $roles');
    unawaited(_syncGoogleProfile(client));
  }

  /// Older accounts (created before the trigger copied the Google photo) get it filled in once.
  static Future<void> _syncGoogleProfile(SupabaseClient client) async {
    try {
      final update = <String, dynamic>{};
      final photo = (_meta['avatar_url'] ?? _meta['picture']) as String?;
      if ((_profile.avatarUrl == null || _profile.avatarUrl!.isEmpty) && photo != null && photo.isNotEmpty) {
        update['avatar_url'] = photo;
      }
      final gName = googleName;
      if (_profile.fullName == 'Harur Resident' && gName != null && gName.trim().isNotEmpty) {
        update['full_name'] = gName.trim();
      }
      if (update.isEmpty) return;
      await client.from('profiles').update(update).eq('id', _profile.id);
      _profile = _profile.copyWith(
        avatarUrl: update['avatar_url'] as String?,
        fullName: update['full_name'] as String?,
      );
      AuthNotifier.instance.notify();
    } catch (e) {
      secureLog('[AUTH] google profile sync skipped: $e');
    }
  }
}

enum AuthFailureReason { cancelled, failed, timeout, network }

enum UsernameLoginResult { ok, invalid, tooManyAttempts, locked, network, error }

enum MfaStatus { unknown, notEnrolled, needsChallenge, satisfied }

class MfaEnrollment {
  final String factorId;
  final String uri;
  final String secret;
  const MfaEnrollment({required this.factorId, required this.uri, required this.secret});
}
