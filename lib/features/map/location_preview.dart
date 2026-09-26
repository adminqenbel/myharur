import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/place.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';

/// Read-only map preview of a saved [PickedLocation], with Google Maps deep links.
/// Text-only locations show the text and a "search in Google Maps" action instead of a map.
class LocationPreview extends StatelessWidget {
  final PickedLocation location;
  final double height;
  const LocationPreview({super.key, required this.location, this.height = 170});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    Future<void> openMaps() => safeLaunch(
          location.hasCoordinates
              ? googleMapsUri(location.lat!, location.lng!).toString()
              : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': location.text}).toString(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (location.hasCoordinates)
          ClipPath(
            clipper: ShapeBorderClipper(shape: squircle(18)),
            child: SizedBox(
              height: height,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(location.lat!, location.lng!),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.myharur.app'),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(location.lat!, location.lng!),
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on_rounded, size: 44, color: AppColors.danger),
                    ),
                  ]),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    attributions: [TextSourceAttribution(t.mapCredit, onTap: () => safeLaunch('https://www.openstreetmap.org/copyright'))],
                  ),
                ],
              ),
            ),
          ),
        if (location.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Row(children: [
              const Icon(Icons.place_rounded, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(child: Text(location.text.trim(), style: AppTextStyles.subheadline)),
            ]),
          ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: PrimaryButton(label: t.openInGoogleMaps, tinted: true, icon: Icons.map_rounded, onPressed: openMaps)),
          if (location.hasCoordinates) ...[
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: t.getDirections,
                tinted: true,
                icon: Icons.directions_rounded,
                onPressed: () => safeLaunch(googleMapsDirectionsUri(location.lat!, location.lng!).toString()),
              ),
            ),
          ],
        ]),
      ],
    );
  }
}
