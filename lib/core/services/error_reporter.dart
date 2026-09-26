import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../util/secure_log.dart';
import 'supabase_config.dart';

// ==============================================================================
// ERROR REPORTER
//
// Every uncaught error goes through [AppErrors.handle]. It never crashes the app itself:
//   • the error is logged (debug only) and queued for the super-admin error log,
//   • three errors within ten seconds (a crash loop) show the friendly crash page,
//   • anything that looks like a token or an e-mail address is removed BEFORE it leaves the phone
//     (the database redacts again, this is defence in depth).
// Reports go through the rate-limited log_client_error() function, and only when signed in;
// errors that happen earlier wait in a small in-memory queue.
// ==============================================================================

class CrashInfo {
  final String message;
  final String? stack;
  const CrashInfo(this.message, this.stack);
}

class _Pending {
  final String kind;
  final String message;
  final String stack;
  final String screen;
  _Pending(this.kind, this.message, this.stack, this.screen);
}

class AppErrors {
  /// Set to show the crash page over the whole app.
  static final ValueNotifier<CrashInfo?> crash = ValueNotifier<CrashInfo?>(null);

  /// Bumped to rebuild the whole app tree ("Restart").
  static final ValueNotifier<int> restartCount = ValueNotifier<int>(0);

  static final List<_Pending> _queue = [];
  static final List<DateTime> _recent = [];
  static final Map<String, DateTime> _lastSeen = {};
  static int _sentThisSession = 0;
  static String? _version;

  static final _token = RegExp(r'eyJ[-A-Za-z0-9_]{8,}(?:\.[-A-Za-z0-9_]+){1,2}');
  static final _email = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');
  static final _longSecret = RegExp(r'[A-Za-z0-9_-]{32,}');

  static String sanitize(String? text, {int max = 2000}) {
    var t = text ?? '';
    t = t.replaceAll(_token, '[token]').replaceAll(_email, '[email]').replaceAll(_longSecret, '[redacted]');
    return t.length > max ? t.substring(0, max) : t;
  }

  static void handle(Object error, StackTrace? stack, {String kind = 'crash', String screen = '', bool allowCrashPage = true}) {
    final message = sanitize(error.toString(), max: 500);
    secureLog('[ERROR] $kind in $screen: $message');

    // ignore exact repeats within a minute (a widget that fails every frame)
    final key = '$kind|$message';
    final now = DateTime.now();
    final last = _lastSeen[key];
    _lastSeen[key] = now;
    if (last != null && now.difference(last) < const Duration(minutes: 1)) return;

    _queue.add(_Pending(kind, message, sanitize(stack?.toString(), max: 4000), screen));
    if (_queue.length > 10) _queue.removeAt(0);
    unawaited(flush());

    _recent.removeWhere((t) => now.difference(t) > const Duration(seconds: 10));
    _recent.add(now);
    if (allowCrashPage && _recent.length >= 3 && crash.value == null) {
      crash.value = CrashInfo(message, stack?.toString() == null ? null : sanitize(stack.toString(), max: 1500));
    }
  }

  /// Shows the crash page immediately (for failures the app cannot continue from).
  static void showCrash(Object error, StackTrace? stack) {
    handle(error, stack, allowCrashPage: false);
    crash.value = CrashInfo(sanitize(error.toString(), max: 500), null);
  }

  static void restart() {
    crash.value = null;
    restartCount.value++;
  }

  static Future<String> _appVersion() async {
    if (_version != null) return _version!;
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _version = 'unknown';
    }
    return _version!;
  }

  static String get _os => kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Sends queued errors if a user is signed in; otherwise keeps them for later.
  static Future<void> flush() async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null || _queue.isEmpty) return;
    final version = await _appVersion();
    while (_queue.isNotEmpty && _sentThisSession < 15) {
      final e = _queue.removeAt(0);
      _sentThisSession++;
      try {
        await client.rpc('log_client_error', params: {
          'p_kind': e.kind,
          'p_message': e.message,
          'p_stack': e.stack,
          'p_screen': e.screen,
          'p_app_version': version,
          'p_os': _os,
        });
      } catch (_) {
        break; // rate limited or offline: never loop, never crash
      }
    }
  }

  /// "Report this problem" button: sends the current crash with the user's OK. Returns success.
  static Future<bool> reportNow(CrashInfo info, {String kind = 'crash', String note = ''}) async {
    final client = SupabaseConfig.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.rpc('log_client_error', params: {
        'p_kind': kind,
        'p_message': sanitize(info.message, max: 500),
        'p_stack': sanitize(info.stack, max: 4000),
        'p_screen': 'crash-page',
        'p_app_version': await _appVersion(),
        'p_os': _os,
        'p_details': sanitize(note, max: 1000),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
