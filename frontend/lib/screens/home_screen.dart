import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInsideDharmapuri = true;
  String _locationName = 'Fetching GPS...';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationName = 'Location Disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationName = 'Permission Denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationName = 'Permission Denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    // Simplified boundary check logic
    bool inBounds = position.latitude >= 11.75 && position.latitude <= 12.35 &&
                    position.longitude >= 77.45 && position.longitude <= 78.75;

    if (mounted) {
      setState(() {
        _isInsideDharmapuri = inBounds;
        _locationName = inBounds ? 'Dharmapuri Region' : 'Outside Service Area';
      });
      if (!inBounds) _showLocationWarningSheet();
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
              Text(l(ref, 'Outside Service Area'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('It looks like you are outside the Dharmapuri/Harur region. Some local services may be restricted.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                  child: const Text('Continue Anyway', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildServiceIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(l(ref, label), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.location_on, color: _isInsideDharmapuri ? Colors.green : Colors.red, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l(ref, _isInsideDharmapuri ? 'Dharmapuri Region' : 'Outside Service Area'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    _locationName,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Tamil/English Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(ref.watch(isEnglishProvider) ? 'அ' : 'A', style: const TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedColor: Colors.blue.shade50,
              onSelected: (_) {
                ref.read(isEnglishProvider.notifier).state = !ref.read(isEnglishProvider.notifier).state;
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rain Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('Heavy rain expected in Harur at 5 PM', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  Icon(Icons.cloudy_snowing, color: Colors.white, size: 48),
                ],
              ),
            ),
            
            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                children: [
                  _buildServiceIcon(Icons.local_offer, 'Daily Deals', Colors.orange),
                  _buildServiceIcon(Icons.work, 'Jobs Nearby', Colors.blue),
                  _buildServiceIcon(Icons.handshake, 'Buy/Sell', Colors.green),
                  _buildServiceIcon(Icons.festival, 'Events', Colors.purple),
                  _buildServiceIcon(Icons.how_to_vote, 'Polls', Colors.teal),
                  _buildServiceIcon(Icons.handyman, 'Services', Colors.brown),
                  _buildServiceIcon(Icons.emoji_events, 'Leaderboard', Colors.amber),
                  _buildServiceIcon(Icons.map, 'Town Map', Colors.indigo),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Hyperlocal Feed Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l(ref, 'Town Feed'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            
            // Mock Feed
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.warning, color: Colors.blue)),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Road Closure Alert', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Salem By-pass road is temporarily closed due to construction work. Please take alternate routes.'),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
