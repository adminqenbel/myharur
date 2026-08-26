import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==============================================================================
// SUPABASE CONFIG — MyHarur Product DB only
// Identity auth (QenBel) is handled via the same Supabase JWT; MyHarur DB
// enforces RLS using that JWT. No separate identity call needed in the app.
// ==============================================================================

/// Inject at build time (optional override):
///   --dart-define=SUPABASE_URL=https://qpuvhhvzygdbvlichbqs.supabase.co
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
///
/// NOTE: The anon key is safe to expose — RLS policies control all data access.
/// The service_role key MUST NEVER appear in Flutter code.
class SupabaseConfig {
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qpuvhhvzygdbvlichbqs.supabase.co',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFwdXZoaHZ6eWdkYnZsaWNoYnFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY3MDExNDksImV4cCI6MjEwMjI3NzE0OX0.HTz325FQBbvIcwfG9_SLvr_jyHqEeUr_gnL6zhmu_tM',
  );

  static bool _initialized = false;
  static String? _initError;

  static bool get isConfigured => _initialized;
  static String? get initError => _initError;

  static Future<void> initialize() async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      _initError = 'SUPABASE_URL or SUPABASE_ANON_KEY not provided. App cannot connect to the database.';
      debugPrint('[SUPABASE] Init failed: $_initError');
      return;
    }
    try {
      await Supabase.initialize(
        url: _url,
        // ignore: deprecated_member_use
        anonKey: _anonKey,
      );
      _initialized = true;
      _initError = null;
      debugPrint('[SUPABASE] Initialized: $_url');
    } catch (e) {
      _initError = 'Supabase initialization error: $e';
      debugPrint('[SUPABASE] $_initError');
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
