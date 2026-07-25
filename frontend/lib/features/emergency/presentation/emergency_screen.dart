import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

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

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Assistance')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: () => _showSnackbar(context, 'SOS Sent! Alerting authorities...'),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.error.withOpacity(0.5), spreadRadius: 10, blurRadius: 20),
                    ],
                  ),
                  child: const Center(
                    child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text('Tap the button above for immediate SOS')),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEmergencyOption(Icons.local_police, 'Police', context),
                _buildEmergencyOption(Icons.local_hospital, 'Ambulance', context),
                _buildEmergencyOption(Icons.fire_extinguisher, 'Fire', context),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/custom_emergency'),
                icon: const Icon(Icons.add_alert),
                label: const Text('Custom Emergency Request'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Emergencies', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<dynamic>>(
                    future: _emergencyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final emergencies = snapshot.data ?? [];
                      if (emergencies.isEmpty) {
                        return const Center(child: Text('No active emergencies nearby.'));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: emergencies.length,
                        itemBuilder: (context, index) {
                          final em = emergencies[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.warning, color: AppTheme.warning),
                              title: Text(em['type'] ?? 'Emergency'),
                              subtitle: Text(em['description'] ?? 'Help needed'),
                              trailing: TextButton(onPressed: () => _showSnackbar(context, 'Navigating to help...'), child: const Text('HELP')),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(IconData icon, String label, BuildContext context) {
    return GestureDetector(
      onTap: () => _showSnackbar(context, 'Calling $label...'),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Icon(icon, size: 30, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

