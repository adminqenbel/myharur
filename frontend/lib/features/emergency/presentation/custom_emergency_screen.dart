import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomEmergencyScreen extends StatefulWidget {
  const CustomEmergencyScreen({super.key});

  @override
  State<CustomEmergencyScreen> createState() => _CustomEmergencyScreenState();
}

class _CustomEmergencyScreenState extends State<CustomEmergencyScreen> {
  String _selectedType = 'Medical';
  final _descriptionController = TextEditingController();
  final LatLng _initialCenter = const LatLng(12.0645, 78.4901); // Harur

  void _submitEmergency() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcasting emergency to nearby helpers...')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Emergency Help')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Emergency Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.harurtown.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _initialCenter,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Emergency Type', border: OutlineInputBorder()),
              items: ['Medical', 'Fire', 'Police', 'Accident', 'Other'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the situation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitEmergency,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('BROADCAST TO NEARBY USERS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
