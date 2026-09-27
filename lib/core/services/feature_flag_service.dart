import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import '../util/secure_log.dart';

// ==============================================================================
// FEATURE FLAG SERVICE — server-controlled module on/off gates
// Reads from module_flags table. All modules default to FALSE at launch.
// Toggled by admin via QenBel Administration without an app store release.
// ==============================================================================
class FeatureFlagService {
  static Map<String, bool> _flags = {
    'jobs': false,
    'events': false,
    'tournaments': false,
    'chat': false,
    'marketplace': false,
    'rankings': false,
    'donations': false,
  };

  static bool _loaded = false;

  /// Load all flags from DB. Call once at app startup after auth is ready.
  static Future<void> loadFlags() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final rows = await client.from('module_flags').select('module, enabled');
      final fetched = <String, bool>{};
      for (final row in rows as List) {
        fetched[row['module'] as String] = row['enabled'] as bool? ?? false;
      }
      if (fetched.isNotEmpty) {
        _flags = {..._flags, ...fetched};
      }
      _loaded = true;
      secureLog('[FLAGS] Loaded: $_flags');
    } catch (e) {
      secureLog('[FLAGS] loadFlags error: $e — using defaults (all off)');
    }
  }

  /// Check if a specific module is enabled.
  static bool isEnabled(String module) => _flags[module] ?? false;

  /// Force-refresh flags (e.g. after admin toggle)
  static Future<void> refresh() => loadFlags();

  static bool get isLoaded => _loaded;

  /// Test hook: sets flags directly, bypassing the network. Widget tests have no Supabase backend.
  @visibleForTesting
  static void debugSetFlags(Map<String, bool> flags) {
    _flags = {..._flags, ...flags};
    _loaded = true;
  }

  /// Modules the app actually reacts to today. Only these are offered as switches in the admin screen —
  /// the others in [_flags] exist in the database for a future module but do nothing yet if turned on.
  static const buildableModules = ['events', 'jobs'];

  /// Turns a module on or off for everyone. Needs a super admin with a two-factor session.
  /// Returns null on success, otherwise the database's error code.
  static Future<String?> adminSetFlag(String module, bool enabled) async {
    final client = SupabaseConfig.client;
    if (client == null) return 'network';
    try {
      await client.rpc('admin_set_module_flag', params: {'p_module': module, 'p_enabled': enabled});
      _flags = {..._flags, module: enabled};
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains('aal2_required')) return 'aal2_required';
      if (e.message.contains('forbidden')) return 'forbidden';
      return 'failed';
    } catch (e) {
      secureLog('[FLAGS] adminSetFlag error: $e');
      return 'failed';
    }
  }
}
