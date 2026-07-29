import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../theme.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _emergencyList = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchEmergencies();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmergencies() async {
    try {
      final response = await ApiClient.dio.get('/emergency/');
      if (mounted) {
        setState(() {
          _emergencyList = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _makeCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildCustomHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryDark : AppTheme.bgLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Emergency',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isDark ? Colors.white : AppTheme.primaryDark,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.history_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: GestureDetector(
          onTap: () {
            // Trigger emergency sequence
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Select Emergency Service', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    _buildEmergencyOption(Icons.local_police_rounded, 'Police', '100', Colors.blue),
                    _buildEmergencyOption(Icons.local_hospital_rounded, 'Ambulance', '108', Colors.red),
                    _buildEmergencyOption(Icons.fire_truck_rounded, 'Fire Station', '101', Colors.orange),
                  ],
                ),
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.emergency,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emergency.withOpacity(0.6),
                        blurRadius: 40 * _pulseAnimation.value,
                        spreadRadius: 10 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(IconData icon, String label, String number, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _makeCall(number);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text('Tap to dial $number', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            Icon(Icons.call_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nearby Services', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildServiceShortcut(Icons.local_hospital_rounded, 'Hospital', Colors.red),
              _buildServiceShortcut(Icons.local_police_rounded, 'Police', Colors.blue),
              _buildServiceShortcut(Icons.fire_truck_rounded, 'Fire', Colors.orange),
              _buildServiceShortcut(Icons.volunteer_activism_rounded, 'Volunteers', AppTheme.primaryYellow),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildServiceShortcut(IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveAlerts() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Area Alerts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          else if (_emergencyList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 32),
                  const SizedBox(width: 16),
                  Expanded(child: Text('No active emergencies in your area. You are safe.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.success))),
                ],
              ),
            )
          else
            ..._emergencyList.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.emergency.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.emergency.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: AppTheme.emergency, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert['type'] ?? 'Emergency', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.emergency)),
                        const SizedBox(height: 4),
                        Text(alert['description'] ?? 'Need assistance', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryYellow,
              onRefresh: _fetchEmergencies,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSOSButton(),
                  _buildNearbyServices(),
                  _buildActiveAlerts(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
