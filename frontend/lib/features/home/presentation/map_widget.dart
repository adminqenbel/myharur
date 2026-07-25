import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HarurMapWidget extends StatelessWidget {
  const HarurMapWidget({super.key});

  // Approximate coordinates for Harur, Tamil Nadu
  static const double harurLat = 12.0645;
  static const double harurLng = 78.4901;
  static final LatLng harurCenter = LatLng(harurLat, harurLng);

  // Define bounds for approximately 10km radius
  // 1 degree latitude is approx 111km. 10km is ~0.09 degrees.
  static final LatLngBounds harurBounds = LatLngBounds(
    LatLng(harurLat - 0.09, harurLng - 0.09), // SouthWest
    LatLng(harurLat + 0.09, harurLng + 0.09), // NorthEast
  );

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: harurCenter,
        initialZoom: 14.5,
        maxZoom: 18.0,
        minZoom: 12.0,
        cameraConstraint: CameraConstraint.contain(bounds: harurBounds),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.harurtown.frontend',
          retinaMode: true,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: harurCenter,
              width: 80,
              height: 80,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
