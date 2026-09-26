import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/util/secure_log.dart';

// ==============================================================================
// Geocoding (OpenStreetMap Nominatim) and the phone's GPS.
//
// Nominatim usage policy: identify the app in the User-Agent, at most 1 request/second,
// no autocomplete-as-you-type hammering. We debounce in the UI and throttle here as well.
// Typed search text and pinned coordinates are sent to OpenStreetMap: this is disclosed on the
// privacy page. Swap the host below for a hosted geocoder before traffic grows.
// ==============================================================================

class GeocodeResult {
  final String label;
  final double lat;
  final double lng;
  const GeocodeResult(this.label, this.lat, this.lng);
}

class GeocodingService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _userAgent = 'MyHarur/1.2 (com.myharur.app; adminqenbel@gmail.com)';
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static Map<String, String> get _headers => {
        if (!kIsWeb) 'User-Agent': _userAgent, // browsers forbid overriding it
        'Accept': 'application/json',
      };

  static Future<void> _throttle() async {
    final wait = _last.add(const Duration(milliseconds: 1100)).difference(DateTime.now());
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _last = DateTime.now();
  }

  static String get _lang => LocaleController.instance.isTamil ? 'ta,en' : 'en';

  /// Search near Harur / Dharmapuri first (biased, not restricted). Returns null when the service
  /// could not be reached, and an empty list when nothing matched.
  static Future<List<GeocodeResult>?> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    try {
      await _throttle();
      final uri = Uri.https(_host, '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'in',
        'accept-language': _lang,
        'viewbox': '77.9,12.5,79.0,11.6', // west,north,east,south around Dharmapuri district
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      return [
        for (final r in list)
          GeocodeResult(
            (r['display_name'] as String? ?? '').split(',').take(4).join(',').trim(),
            double.parse(r['lat'] as String),
            double.parse(r['lon'] as String),
          ),
      ];
    } catch (e) {
      secureLog('[GEO] search failed: $e');
      return null;
    }
  }

  /// A readable address for a pin, or null if unavailable.
  static Future<String?> reverse(double lat, double lng) async {
    try {
      await _throttle();
      final uri = Uri.https(_host, '/reverse', {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'jsonv2',
        'zoom': '17',
        'accept-language': _lang,
      });
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final name = (jsonDecode(res.body) as Map)['display_name'] as String?;
      return name?.split(',').take(4).join(',').trim();
    } catch (e) {
      secureLog('[GEO] reverse failed: $e');
      return null;
    }
  }
}

enum LocationProblem { serviceDisabled, denied, deniedForever, timeout, failed }

class CurrentLocationResult {
  final LatLng? position;
  final LocationProblem? problem;
  const CurrentLocationResult.ok(LatLng this.position) : problem = null;
  const CurrentLocationResult.error(LocationProblem this.problem) : position = null;
}

/// The phone's location, only when the user explicitly asks for it (foreground, one-shot).
class DeviceLocation {
  static Future<CurrentLocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const CurrentLocationResult.error(LocationProblem.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return const CurrentLocationResult.error(LocationProblem.deniedForever);
      }
      if (permission == LocationPermission.denied) return const CurrentLocationResult.error(LocationProblem.denied);

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return CurrentLocationResult.ok(LatLng(p.latitude, p.longitude));
    } on TimeoutException {
      return const CurrentLocationResult.error(LocationProblem.timeout);
    } catch (e) {
      secureLog('[GEO] current location failed: $e');
      return const CurrentLocationResult.error(LocationProblem.failed);
    }
  }
}
