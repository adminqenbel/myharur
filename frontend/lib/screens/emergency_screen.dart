import 'package:flutter/material.dart';
import '../api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Future<List<dynamic>> _emergencyFuture;

  @override
  void initState() {
    super.initState();
    _emergencyFuture = _fetchEmergencies();
  }

  Future<List<dynamic>> _fetchEmergencies() async {
    final response = await ApiClient.dio.get('/emergency/');
    return response.data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _emergencyFuture = _fetchEmergencies();
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Emergency Assistance'),
                      content: const Text('Who do you need to contact?'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final Uri url = Uri(scheme: 'tel', path: '100');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: const Text('Police (100)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final Uri url = Uri(scheme: 'tel', path: '108');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: const Text('Medical (108)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 30, spreadRadius: 10),
                    ],
                  ),
                  child: const Center(
                    child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tap the button in an emergency', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Active Alerts Nearby', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: _emergencyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load active alerts.'));
                }

                final alerts = snapshot.data ?? [];
                if (alerts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No active emergency alerts in your area. You are safe.', style: TextStyle(color: Colors.green, fontSize: 16)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(alert['type'] ?? 'Emergency Alert', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        subtitle: Text(alert['description'] ?? 'Need assistance'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
