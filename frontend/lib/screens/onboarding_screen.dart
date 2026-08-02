import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPS() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_firstNameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post('/users/me/setup', data: {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'ward': _wardCtrl.text.trim(),
        'location_lat': _lat,
        'location_lng': _lng,
      });
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= _currentPage ? Colors.blue : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)
                      : Text(_currentPage == 2 ? 'Get Started!' : 'Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.waving_hand, size: 48, color: AppTheme.appleBlue),
          SizedBox(height: 16),
          Text('Welcome to MyHarur!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Let's set up your profile so the community knows who you are.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          SizedBox(height: 32),
          TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
          SizedBox(height: 16),
          TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_city, size: 48, color: Colors.blue),
          SizedBox(height: 16),
          Text('Where do you live?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('This helps us show you the most relevant local content. (Optional)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          SizedBox(height: 32),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Street / Area (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home))),
          SizedBox(height: 16),
          TextField(controller: _wardCtrl, decoration: const InputDecoration(labelText: 'Ward / Neighbourhood', border: OutlineInputBorder())),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetchGPS,
            icon: Icon(Icons.my_location),
            label: Text(_lat != null ? 'GPS Fetched ✓' : 'Auto-detect GPS Location'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              foregroundColor: _lat != null ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 24),
          Text('All Set!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('Your profile is ready. You now have full access to the MyHarur community — live news, deals, jobs, events, and more!', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
          SizedBox(height: 32),
          _buildPreviewRow(Icons.explore, 'Explore your town\'s live feed'),
          SizedBox(height: 12),
          _buildPreviewRow(Icons.local_offer, 'Find daily deals from local shops'),
          SizedBox(height: 12),
          _buildPreviewRow(Icons.groups, 'Join the community, vote on polls'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 15)),
      ],
    );
  }
}
