import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../api_client.dart';
import 'package:dio/dio.dart';
import '../theme.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isLoading = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _reportEmergency(String type, String category) async {
    setState(() => _isLoading = true);
    try {
      // Mock coordinates for demo
      final payload = {
        "type": type,
        "category": category,
        "lat": 12.064,
        "lng": 78.490
      };
      await ApiClient.dio.post('/emergency/', data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully reported: $category! Alerting network...')));
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGrievanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String selectedCategory = 'road';
        return StatefulBuilder(builder: (context, setStateBuilder) {
          return AlertDialog(
            title: Text(l(ref, 'Report Grievance')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'road', child: Text('Road/Pothole')),
                    DropdownMenuItem(value: 'water', child: Text('Water Supply')),
                    DropdownMenuItem(value: 'electricity', child: Text('Electricity')),
                  ],
                  onChanged: (v) => setStateBuilder(() => selectedCategory = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reportEmergency('govt_grievance', selectedCategory);
                },
                child: const Text('Submit'),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(ref, 'Citizen Report & SOS')),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.emergency, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Emergency SOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_police, size: 28),
              label: Text(l(ref, 'Police SOS Alert'), style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => _reportEmergency('citizen_sos', 'medical'), // Mapped to general SOS
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.bloodtype, size: 28),
              label: Text(l(ref, 'Urgent Blood Required'), style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => _reportEmergency('citizen_sos', 'blood'),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            const Text('Citizen Reporting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Report garbage, potholes, or broken streetlights to the community.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.report_problem),
              label: Text(l(ref, 'Report Govt Grievance')),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _showGrievanceDialog,
            ),
          ],
        ),
      ),
    );
  }
}
