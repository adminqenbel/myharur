import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_session_storage.dart';
import '../util/secure_log.dart';

// ==============================================================================
// SUPABASE CONFIG — MyHarur product DB
//
// Both values are PUBLIC client credentials (project URL + publishable key); all
// data access is enforced by RLS. The service_role / secret key must NEVER appear
// in Flutter code.
//
// Override at build time (CI and Dockerfile already pass these names):
//   --dart-define=SUPABASE_URL=https://<ref>.supabase.co
//   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
// ==============================================================================
class SupabaseConfig {
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qpuvhhvzygdbvlichbqs.supabase.co',
  );
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_Fl1qvB5E-gt2hxwE6QDXpQ_7SuU3ZPV',
  );

  static bool _initialized = false;
  static String? _initError;

  static String get url => _url;
  static String get publishableKey => _publishableKey;
  static bool get isConfigured => _initialized;
  static String? get initError => _initError;

  static Future<void> initialize() async {
    if (_url.isEmpty || _publishableKey.isEmpty) {
      _initError = 'SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY not provided. App cannot connect to the database.';
      secureLog('[SUPABASE] Init failed: $_initError');
      return;
    }
    try {
      await Supabase.initialize(
        url: _url,
        publishableKey: _publishableKey,
        // Encrypted session storage on Android (web keeps the browser default). PKCE is the default flow.
        authOptions: const FlutterAuthClientOptions(
          localStorage: kIsWeb ? null : SecureSessionStorage(),
        ),
      );
      _initialized = true;
      _initError = null;
      secureLog('[SUPABASE] Initialized: $_url');
    } catch (e) {
      _initError = 'Supabase initialization error: $e';
      secureLog('[SUPABASE] $_initError');
    }
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
