import 'dart:ui';
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: const Text('MyHarur', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white.withOpacity(0.2),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon!')));
                  },
                )
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation != null ? _userLocation! : _defaultCenter,
              initialZoom: 12.0,
              cameraConstraint: CameraConstraint.contain(bounds: _dharmapuriBounds),
              onTap: (tapPosition, point) {
                if (mounted) {
                  setState(() {
                    _userLocation = point;
                    _isInsideDharmapuri = _dharmapuriBounds.contains(point);
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.adminqenbel.myharur',
                retinaMode: true,
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(Icons.location_on, color: _isInsideDharmapuri ? Colors.blue : Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          if (_userLocation != null && !_isInsideDharmapuri)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You are outside Dharmapuri zone. Please tap the map to pick a manual location.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }
}
