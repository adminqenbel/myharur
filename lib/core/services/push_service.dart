import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_controller.dart';
import '../util/secure_log.dart';
import 'supabase_config.dart';

// ==============================================================================
// PUSH NOTIFICATIONS (Firebase Cloud Messaging).
//
// Deliberately quiet: one report summary a day at most, event alerts at most twice a week, nothing between
// 10 pm and 7 am (India time). The caps are enforced in the database, not here. Every person can switch it
// all off, or each kind, in Account > Notifications. The permission is requested when the person turns it on
// (or accepts the one-time prompt), never at launch.
//
// Firebase needs a per-project config file (android/app/google-services.json). Without it the app runs
// normally and this service reports [PushState.unavailable].
// ==============================================================================
enum PushState { unknown, unavailable, blocked, off, on }

class NotificationPrefs {
  final bool enabled;
  final bool reports;
  final bool events;
  const NotificationPrefs({this.enabled = true, this.reports = true, this.events = true});

  NotificationPrefs copyWith({bool? enabled, bool? reports, bool? events}) =>
      NotificationPrefs(enabled: enabled ?? this.enabled, reports: reports ?? this.reports, events: events ?? this.events);
}

/// The Firebase calls the service needs, so tests can replace them.
abstract class PushBackend {
  Future<bool> firebaseReady();
  Future<bool> permissionGranted();
  Future<bool> requestPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<void> get onNotificationOpened;
  Future<bool> launchedFromNotification();
}

class FirebasePushBackend implements PushBackend {
  bool? _ready;

  @override
  Future<bool> firebaseReady() async {
    if (kIsWeb) return false; // browser push needs its own set-up; the app targets Android first
    if (_ready != null) return _ready!;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      secureLog('[PUSH] Firebase not configured: ${e.runtimeType}');
      _ready = false;
    }
    return _ready!;
  }

  @override
  Future<bool> permissionGranted() async {
    final s = await FirebaseMessaging.instance.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.authorized || s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<bool> requestPermission() async {
    final s = await FirebaseMessaging.instance.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized || s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<void> get onNotificationOpened => FirebaseMessaging.onMessageOpenedApp.map((_) {});

  @override
  Future<bool> launchedFromNotification() async => (await FirebaseMessaging.instance.getInitialMessage()) != null;
}

class PushService {
  static PushBackend _backend = FirebasePushBackend();
  static final ValueNotifier<PushState> state = ValueNotifier(PushState.unknown);

  /// Bumped when the person taps a notification, so the app can open the Reports tab.
  static final ValueNotifier<int> openReportsRequests = ValueNotifier(0);

  static StreamSubscription<String>? _tokenSub;
  static StreamSubscription<void>? _openSub;
  static bool _listening = false;
  static String? _registeredToken;

  @visibleForTesting
  static void debugUseBackend(PushBackend b) {
    _backend = b;
    state.value = PushState.unknown;
    _listening = false;
    _registeredToken = null;
    _tokenSub?.cancel();
    _openSub?.cancel();
  }

  static SupabaseClient? get _c => SupabaseConfig.client;
  static String get _lang => LocaleController.instance.locale.languageCode == 'ta' ? 'ta' : 'en';

  // ── preferences (server) ─────────────────────────────────────────────────────

  static Future<NotificationPrefs?> prefs() async {
    try {
      final r = await _c?.rpc('my_notification_prefs');
      final row = r is List && r.isNotEmpty ? Map<String, dynamic>.from(r.first as Map) : (r is Map ? Map<String, dynamic>.from(r) : null);
      if (row == null) return null;
      return NotificationPrefs(enabled: row['enabled'] == true, reports: row['reports'] == true, events: row['events'] == true);
    } catch (e) {
      secureLog('[PUSH] prefs failed: ${e.runtimeType}');
      return null;
    }
  }

  static Future<bool> savePrefs(NotificationPrefs p) async {
    try {
      await _c?.rpc('set_notification_prefs', params: {'p_enabled': p.enabled, 'p_reports': p.reports, 'p_events': p.events});
      return true;
    } catch (e) {
      secureLog('[PUSH] savePrefs failed: ${e.runtimeType}');
      return false;
    }
  }

  // ── state ────────────────────────────────────────────────────────────────────

  /// Works out where things stand: no Firebase config, permission blocked, switched off, or on.
  static Future<PushState> refresh() async {
    if (!await _backend.firebaseReady()) return state.value = PushState.unavailable;
    final p = await prefs();
    final granted = await _backend.permissionGranted();
    if (p != null && !p.enabled) return state.value = PushState.off;
    if (!granted) return state.value = p == null ? PushState.off : PushState.blocked;
    return state.value = PushState.on;
  }

  /// Asks for permission (if needed), registers this phone and turns notifications on.
  /// Returns the resulting state ([PushState.blocked] when the person refused).
  static Future<PushState> turnOn() async {
    if (!await _backend.firebaseReady()) return state.value = PushState.unavailable;
    if (!await _backend.requestPermission()) {
      final p = (await prefs()) ?? const NotificationPrefs();
      await savePrefs(p.copyWith(enabled: false));
      return state.value = PushState.blocked;
    }
    final p = (await prefs()) ?? const NotificationPrefs();
    await savePrefs(p.copyWith(enabled: true));
    await _register();
    _listen();
    return state.value = PushState.on;
  }

  static Future<PushState> turnOff() async {
    final p = (await prefs()) ?? const NotificationPrefs();
    await savePrefs(p.copyWith(enabled: false));
    await unregisterThisDevice();
    return state.value = PushState.off;
  }

  /// Called after a person is signed in: if notifications are on, keep this phone registered
  /// (the token can change, and a shared phone moves between accounts).
  static Future<void> syncOnSignIn() async {
    _watchOpens(); // tapping a notification opens Reports, signed in or not
    if (_c?.auth.currentUser == null) return;
    if (await refresh() == PushState.on) {
      await _register();
      _listen();
    }
  }

  /// Removes this phone from the signed-in account (call before signing out).
  static Future<void> unregisterThisDevice() async {
    final t = _registeredToken ?? (await _backend.firebaseReady() ? await _backend.token() : null);
    if (t != null) {
      try {
        await _c?.rpc('unregister_push_token', params: {'p_token': t});
      } catch (_) {}
    }
    _registeredToken = null;
  }

  // ── internals ────────────────────────────────────────────────────────────────

  static Future<void> _register([String? given]) async {
    try {
      final t = given ?? await _backend.token();
      if (t == null || t.isEmpty || _c?.auth.currentUser == null) return;
      await _c?.rpc('register_push_token', params: {'p_token': t, 'p_lang': _lang, 'p_platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'});
      _registeredToken = t;
    } catch (e) {
      secureLog('[PUSH] register failed: ${e.runtimeType}');
    }
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _tokenSub = _backend.onTokenRefresh.listen((t) => _register(t));
    LocaleController.instance.addListener(() {
      if (state.value == PushState.on) _register(); // the summary follows the app language
    });
  }

  static void _watchOpens() {
    if (_openSub != null) return;
    unawaited(() async {
      try {
        if (!await _backend.firebaseReady()) return;
        if (await _backend.launchedFromNotification()) openReportsRequests.value++;
        _openSub = _backend.onNotificationOpened.listen((_) => openReportsRequests.value++);
      } catch (_) {}
    }());
  }
}
