import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _userLocation;
  bool _isInsideDharmapuri = false;
  
  // Dharmapuri Bounds (Approximate bounding box)
  final LatLngBounds _dharmapuriBounds = LatLngBounds(
    const LatLng(11.7500, 77.4500), // South West
    const LatLng(12.3500, 78.7500), // North East
  );
  
  final LatLng _defaultCenter = const LatLng(12.0621, 78.4891); // Harur center

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _userLocation = currentLatLng;
        _isInsideDharmapuri = _dharmapuriBounds.contains(currentLatLng);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyHarur Map')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _isInsideDharmapuri && _userLocation != null ? _userLocation! : _defaultCenter,
          initialZoom: 12.0,
          cameraConstraint: CameraConstraint.contain(bounds: _dharmapuriBounds),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.adminqenbel.myharur',
            retinaMode: true,
          ),
          if (_isInsideDharmapuri && _userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
