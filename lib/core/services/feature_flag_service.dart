import 'package:flutter/foundation.dart';
import 'supabase_config.dart';

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
      debugPrint('[FLAGS] Loaded: $_flags');
    } catch (e) {
      debugPrint('[FLAGS] loadFlags error: $e — using defaults (all off)');
    }
  }

  /// Check if a specific module is enabled.
  static bool isEnabled(String module) => _flags[module] ?? false;

  /// Force-refresh flags (e.g. after admin toggle)
  static Future<void> refresh() => loadFlags();

  static bool get isLoaded => _loaded;
}
