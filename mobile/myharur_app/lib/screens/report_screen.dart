import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';
import '../l10n/translations.dart';
import '../api_client.dart';
import 'package:dio/dio.dart';
import '../theme.dart';
import '../widgets/design_system.dart';

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
      final msg = e.error != null ? e.error.toString() : 'Failed to report.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
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
                  items: [
                    DropdownMenuItem(value: 'road', child: Text('Road/Pothole')),
                    DropdownMenuItem(value: 'water', child: Text('Water Supply')),
                    DropdownMenuItem(value: 'electricity', child: Text('Electricity')),
                  ],
                  onChanged: (v) => setStateBuilder(() => selectedCategory = v!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reportEmergency('govt_grievance', selectedCategory);
                },
                child: Text('Submit'),
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
        backgroundColor: AppTheme.danger,
        foregroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.emergency, size: 80, color: AppTheme.danger),
            SizedBox(height: 16),
            Text('Emergency SOS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 24),
            MHButton(
              icon: Icons.local_police,
              text: l(ref, 'Police SOS Alert'),
              onPressed: () => _reportEmergency('citizen_sos', 'medical'), // Mapped to general SOS
            ),
            SizedBox(height: 16),
            MHButton(
              icon: Icons.bloodtype,
              text: l(ref, 'Urgent Blood Required'),
              onPressed: () => _reportEmergency('citizen_sos', 'blood'),
            ),
            SizedBox(height: 48),
            Divider(),
            SizedBox(height: 24),
            Text('Citizen Reporting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Report garbage, potholes, or broken streetlights to the community.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            SizedBox(height: 16),
            MHOutlinedButton(
              icon: Icons.report_problem,
              text: l(ref, 'Report Govt Grievance'),
              onPressed: _showGrievanceDialog,
            ),
          ],
        ),
      ),
    );
  }
}
