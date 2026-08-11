import 'package:shared_preferences/shared_preferences.dart';

/// Persists location preferences so the "outside zone" warning
/// shows only ONCE per login session, not on every app open.
class LocationPrefs {
  static const _keyShownWarning = 'location_warning_shown';
  static const _keyManualLat = 'manual_location_lat';
  static const _keyManualLng = 'manual_location_lng';
  static const _keyManualName = 'manual_location_name';
  static const _keyUseManual = 'use_manual_location';

  /// Returns true if the out-of-zone warning was already shown this session.
  static Future<bool> wasWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShownWarning) ?? false;
  }

  static Future<void> markWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShownWarning, true);
  }

  /// Call on logout to reset so the warning shows again on next login.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyShownWarning);
  }

  // ── Manual location ──────────────────────────────────────────────────────

  static Future<bool> hasManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseManual) ?? false;
  }

  static Future<Map<String, dynamic>?> getManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyUseManual) != true) return null;
    return {
      'lat': prefs.getDouble(_keyManualLat),
      'lng': prefs.getDouble(_keyManualLng),
      'name': prefs.getString(_keyManualName) ?? 'Custom Location',
    };
  }

  static Future<void> saveManualLocation(double lat, double lng, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyManualLat, lat);
    await prefs.setDouble(_keyManualLng, lng);
    await prefs.setString(_keyManualName, name);
    await prefs.setBool(_keyUseManual, true);
  }

  static Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyManualLat);
    await prefs.remove(_keyManualLng);
    await prefs.remove(_keyManualName);
    await prefs.remove(_keyUseManual);
  }
}
