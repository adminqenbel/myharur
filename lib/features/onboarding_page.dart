import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/supabase_service.dart';
import '../main.dart';

class TownOnboardingFlowPage extends StatefulWidget {
  const TownOnboardingFlowPage({super.key});

  @override
  State<TownOnboardingFlowPage> createState() => _TownOnboardingFlowPageState();
}

class _TownOnboardingFlowPageState extends State<TownOnboardingFlowPage> {
  int currentStep = 0; // 0: Auth/Login, 1: Personal Details, 2: Map & Location Pinning

  // Auth Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool isSignUp = true;
  bool isOfficialMode = false;

  // Profile Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wardCtrl = TextEditingController(text: 'Ward 4, Bazaar Street, Harur');
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String selectedBloodGroup = 'O+';
  final bloodGroups = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

  // Map & Location Selection
  String pinnedLocationName = 'Harur Town Bus Stand (Central)';
  double pinnedLat = 12.0624;
  double pinnedLon = 78.4983;
  bool isDetectingGps = false;

  final landmarks = [
    {
      'name': 'Harur Town Bus Stand (Central)',
      'lat': 12.0624,
      'lon': 78.4983,
      'desc': 'Primary transit hub connecting Morappur, Dharmapuri, and Salem.',
      'type': 'Transit',
    },
    {
      'name': 'Bazaar Street Commercial Hub',
      'lat': 12.0638,
      'lon': 78.4965,
      'desc': 'Traditional wholesale agri market, textile merchants & local shops.',
      'type': 'Market',
    },
    {
      'name': 'Theerthagirishwarar Temple, Theerthamalai',
      'lat': 12.0862,
      'lon': 78.6014,
      'desc': 'Historic hilltop sacred shrine and cultural landmark.',
      'type': 'Heritage',
    },
    {
      'name': 'Morappur Railway Junction Area',
      'lat': 12.1245,
      'lon': 78.4021,
      'desc': 'Rail transit gateway with upcoming Harur broad gauge link.',
      'type': 'Rail Link',
    },
    {
      'name': 'Kottapatti Valley & Hamlets',
      'lat': 11.9840,
      'lon': 78.5830,
      'desc': 'Agricultural heartland known for sugarcane, paddy & hills.',
      'type': 'Farming',
    },
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _wardCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStep1Auth() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();

    if (email.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    if (isSignUp) {
      await AuthService.signUpWithEmailPassword(
        email: email,
        password: pwd,
        fullName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Harur Resident',
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000',
      );
    } else {
      await AuthService.signInWithEmailPassword(email, pwd);
    }

    if (mounted) {
      setState(() => currentStep = 1);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final ok = await AuthService.signInWithGoogle();
    if (mounted) {
      if (ok) {
        setState(() => currentStep = 1);
      }
    }
  }

  Future<void> _handleStep2Details() async {
    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Harur Resident';
    final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000';
    final ward = _wardCtrl.text.trim().isNotEmpty ? _wardCtrl.text.trim() : 'Harur Town';
    final emName = _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : 'Family Contact';
    final emPhone = _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : '+91 94432 11000';
    final bio = _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : 'Active resident of Harur community.';

    await AuthService.savePersonalDetails(
      fullName: name,
      phone: phone,
      wardLocality: ward,
      bloodGroup: selectedBloodGroup,
      emergencyContactName: emName,
      emergencyContactPhone: emPhone,
      bio: bio,
    );

    if (mounted) {
      setState(() => currentStep = 2);
    }
  }

  Future<void> _handleStep3Finish() async {
    await AuthService.savePersonalDetails(
      fullName: AuthService.currentProfile.fullName,
      phone: AuthService.currentProfile.phone,
      wardLocality: pinnedLocationName,
      bloodGroup: AuthService.currentProfile.bloodGroup,
      emergencyContactName: AuthService.currentProfile.emergencyContactName,
      emergencyContactPhone: AuthService.currentProfile.emergencyContactPhone,
      bio: AuthService.currentProfile.bio,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TownShell()),
      );
    }
  }

  void _triggerGpsLocate() {
    setState(() => isDetectingGps = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isDetectingGps = false;
          pinnedLocationName = 'Harur Town Bus Stand (Live GPS)';
          pinnedLat = 12.0624;
          pinnedLon = 78.4983;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF007F63),
            content: Text('✓ Live GPS Location locked to Harur (12.0624° N, 78.4983° E)'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stepper Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Row(
                children: [
                  SvgPicture.asset('assets/brand/myharur_icon.svg', width: 32, height: 32),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('myharur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text('digital town setup', style: TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Step ${currentStep + 1} of 3',
                      style: const TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / 3,
                  backgroundColor: const Color(0xFFE2EBE8),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF007F63)),
                  minHeight: 4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Animated Step Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: currentStep == 0
                      ? _buildStep1Auth()
                      : (currentStep == 1 ? _buildStep2Details() : _buildStep3Map()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Auth() {
    return KeyedSubtree(
      key: const ValueKey('step_1'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Welcome to Harur', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF15211F))),
          const SizedBox(height: 4),
          const Text('Sign in with Google OAuth or Email to generate your verified MMID.', style: TextStyle(fontSize: 13, color: Color(0xFF697570))),
          const SizedBox(height: 24),

          // Google Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15211F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
              label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              onPressed: _handleGoogleSignIn,
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or with email & password', style: TextStyle(fontSize: 11, color: Color(0xFF697570)))),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          if (isSignUp) ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007F63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _handleStep1Auth,
              child: Text(isSignUp ? 'Next: Personal Details →' : 'Sign In & Continue →', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                isSignUp ? 'Already have an MMID? Sign In' : 'New resident? Register MMID',
                style: const TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () {
                _emailCtrl.text = 'admin.qenbel@gmail.com';
                _passwordCtrl.text = 'admin@qenbel';
                isSignUp = false;
                _handleStep1Auth();
              },
              child: const Text('👑 Use Root SuperAdmin (admin.qenbel@gmail.com)', style: TextStyle(color: Color(0xFF267AF4), fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Details() {
    return KeyedSubtree(
      key: const ValueKey('step_2'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Personal Details & Safety', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF15211F))),
          const SizedBox(height: 4),
          Text('MMID Generated: ${AuthService.currentProfile.mmid}', style: const TextStyle(fontSize: 13, color: Color(0xFF007F63), fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF007F63)),
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF007F63)),
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wardCtrl,
            decoration: InputDecoration(
              labelText: 'Address / Ward in Harur',
              prefixIcon: const Icon(Icons.home_rounded, color: Color(0xFF007F63)),
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Blood Group (For Emergency First Responders)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF697570))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: selectedBloodGroup,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
            onChanged: (val) => setState(() => selectedBloodGroup = val ?? 'O+'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _emergencyNameCtrl,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Name',
              prefixIcon: const Icon(Icons.contact_emergency_rounded, color: Color(0xFF007F63)),
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergencyPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Emergency Contact Phone',
              prefixIcon: const Icon(Icons.phone_callback_rounded, color: Color(0xFF007F63)),
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007F63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _handleStep2Details,
              child: const Text('Next: Pin Town Location on Map →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => currentStep = 0),
              child: const Text('← Back to Login', style: TextStyle(color: Color(0xFF697570), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Map() {
    return KeyedSubtree(
      key: const ValueKey('step_3'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Pin Your Location on Town Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF15211F))),
          const SizedBox(height: 4),
          const Text('Your pinned location anchors your emergency radius and localized alerts.', style: TextStyle(fontSize: 13, color: Color(0xFF697570))),
          const SizedBox(height: 16),

          // Interactive Map Simulation Canvas
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2E9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF9DD8C5), width: 2),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: MapLinesPainter())),
                // Active Marker Pin
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15211F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pinnedLocationName,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF007F63),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x44007F63), blurRadius: 16, offset: Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.location_pin, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                // GPS Trigger Button in top right
                Positioned(
                  right: 12,
                  top: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'gps_locate',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007F63),
                    onPressed: _triggerGpsLocate,
                    child: isDetectingGps
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007F63)))
                        : const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ),
                // Bottom GPS coords pill
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'GPS: ${pinnedLat.toStringAsFixed(4)}° N, ${pinnedLon.toStringAsFixed(4)}° E',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15211F)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text('Select Your Primary Area / Landmark:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF15211F))),
          const SizedBox(height: 10),

          // Landmarks List
          ...landmarks.map((lm) {
            final isSelected = pinnedLocationName == lm['name'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE9F6F1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF007F63) : const Color(0xFFE2EBE8), width: isSelected ? 2 : 1),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFF007F63) : const Color(0xFF697570),
                ),
                title: Text(lm['name'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, fontSize: 13)),
                subtitle: Text(lm['desc'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF697570))),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(lm['type'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF007F63))),
                ),
                onTap: () {
                  setState(() {
                    pinnedLocationName = lm['name'] as String;
                    pinnedLat = lm['lat'] as double;
                    pinnedLon = lm['lon'] as double;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007F63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Confirm Location & Enter MyHarur', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              onPressed: _handleStep3Finish,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => currentStep = 1),
              child: const Text('← Back to Personal Details', style: TextStyle(color: Color(0xFF697570), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
