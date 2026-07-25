import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyHarur Map')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(12.0621, 78.4891), // MyHarur Coordinates
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.adminqenbel.myharur',
            retinaMode: true,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: const LatLng(12.0621, 78.4891),
                width: 80,
                height: 80,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
