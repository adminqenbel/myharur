/// A place chosen by the user: a pinned map point, typed text, or both.
///
/// Used for the optional profile address and for the location of a report, event or job.
/// Everything is optional: text without coordinates is a typed address, coordinates without text
/// is a bare pin, and [source] records how it was chosen ('map' | 'typed' | 'gps').
class PickedLocation {
  final double? lat;
  final double? lng;
  final String text;
  final String source;

  const PickedLocation({this.lat, this.lng, this.text = '', this.source = 'typed'});

  bool get hasCoordinates => lat != null && lng != null;
  bool get isEmpty => !hasCoordinates && text.trim().isEmpty;

  /// Short label for lists and rows.
  String get label => text.trim().isNotEmpty ? text.trim() : (hasCoordinates ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}' : '');

  static PickedLocation? fromColumns({String? text, double? lat, double? lng, String? source}) {
    final p = PickedLocation(lat: lat, lng: lng, text: text ?? '', source: source ?? (lat != null ? 'map' : 'typed'));
    return p.isEmpty ? null : p;
  }

  /// Column values for the database (profile: address_*, alert: location_*).
  Map<String, dynamic> toColumns(String prefix) => {
        '${prefix}_text': text.trim().isEmpty ? null : text.trim(),
        '${prefix}_lat': lat,
        '${prefix}_lng': lng,
        '${prefix}_source': isEmpty ? null : source,
      };

  @override
  bool operator ==(Object other) => other is PickedLocation && other.lat == lat && other.lng == lng && other.text == text && other.source == source;

  @override
  int get hashCode => Object.hash(lat, lng, text, source);
}

/// Harur town centre: where every map opens by default.
const double kHarurLat = 12.0624;
const double kHarurLng = 78.4983;
