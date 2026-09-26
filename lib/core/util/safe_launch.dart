import 'package:url_launcher/url_launcher.dart';
import 'secure_log.dart';

/// Schemes the app is willing to open. Anything else (javascript:, file:, intent:, content:, http:)
/// is refused, because links come from user-submitted content and crawled feeds.
const Set<String> kAllowedLinkSchemes = {'https', 'tel', 'mailto', 'geo'};

/// Returns the parsed [Uri] only if it is safe to open, otherwise null.
Uri? parseSafeUri(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty || value.length > 2048) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !kAllowedLinkSchemes.contains(uri.scheme.toLowerCase())) return null;
  if (uri.scheme.toLowerCase() == 'https' && uri.host.isEmpty) return null;
  // Credentials in a URL (https://trusted.com@evil.com) are a classic phishing trick.
  if (uri.userInfo.isNotEmpty) return null;
  return uri;
}

/// Opens [url] in the external app/browser if (and only if) it passes [parseSafeUri].
/// Returns whether something was launched.
Future<bool> safeLaunch(String? url) async {
  final uri = parseSafeUri(url);
  if (uri == null) {
    secureLog('[LINK] refused to open a link with a disallowed scheme');
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    secureLog('[LINK] launch failed: $e');
    return false;
  }
}

/// Google Maps link for a pinned location (opens the Maps app when installed, otherwise the browser).
Uri googleMapsUri(double lat, double lng) =>
    Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$lat,$lng'});

/// Turn-by-turn directions to a pinned location.
Uri googleMapsDirectionsUri(double lat, double lng) =>
    Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': '$lat,$lng'});
