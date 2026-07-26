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
      
      if (!_isInsideDharmapuri) {
        _showLocationWarningSheet();
      }
    }
  }

  void _showLocationWarningSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Outside Service Area', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('It looks like you are outside the Dharmapuri/Harur region. Please tap the map to pick a manual location within the boundary to use the town services.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Pick Manual Location', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              toolbarHeight: 80,
              backgroundColor: Colors.white.withOpacity(0.85),
              elevation: 0,
              title: Row(
                children: [
                  Icon(Icons.location_on, color: _isInsideDharmapuri ? Colors.green : Colors.red, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isInsideDharmapuri ? 'Dharmapuri Region' : 'Outside Service Area',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        Text(
                          _userLocation != null ? 'Tap map to refine location' : 'Fetching GPS...',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.black87),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile coming soon!')));
                  },
                ),
                const SizedBox(width: 8),
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
