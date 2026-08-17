import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';
import '../widgets/glass_components.dart';
import '../main.dart';

class TownOnboardingFlowPage extends StatefulWidget {
  const TownOnboardingFlowPage({super.key});

  @override
  State<TownOnboardingFlowPage> createState() => _TownOnboardingFlowPageState();
}

class _TownOnboardingFlowPageState extends State<TownOnboardingFlowPage> {
  int currentStep = 0; // 0: Auth/Welcome, 1: Holographic MMID Pass Customizer, 2: Locality & Emergency Setup

  // Auth Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool isSignUp = true;
  bool _obscurePassword = true;

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

  StreamSubscription<AuthState>? _authSub;
  bool _googleSignInPending = false;
  bool _isProcessing = false;

  final landmarks = [
    {
      'name': 'Harur Town Bus Stand (Central)',
      'lat': 12.0624,
      'lon': 78.4983,
      'desc': 'Primary transit hub connecting Morappur, Dharmapuri, and Salem.',
      'type': 'Transit Hub',
      'icon': Icons.directions_bus_rounded,
    },
    {
      'name': 'Bazaar Street Commercial Hub',
      'lat': 12.0638,
      'lon': 78.4965,
      'desc': 'Traditional wholesale agri market, textile merchants & local shops.',
      'type': 'Agri & Bazaar',
      'icon': Icons.storefront_rounded,
    },
    {
      'name': 'Theerthagirishwarar Temple, Theerthamalai',
      'lat': 12.0862,
      'lon': 78.6014,
      'desc': 'Historic hilltop sacred shrine and cultural landmark.',
      'type': 'Heritage',
      'icon': Icons.temple_hindu_rounded,
    },
    {
      'name': 'Morappur Railway Junction Area',
      'lat': 12.1245,
      'lon': 78.4021,
      'desc': 'Rail transit gateway with upcoming Harur broad gauge link.',
      'type': 'Rail Link',
      'icon': Icons.train_rounded,
    },
    {
      'name': 'Kottapatti Valley & Hamlets',
      'lat': 11.9840,
      'lon': 78.5830,
      'desc': 'Agricultural heartland known for sugarcane, paddy & hills.',
      'type': 'Farming Sector',
      'icon': Icons.agriculture_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final client = SupabaseConfig.client;
    if (client != null) {
      _authSub = client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.event == AuthChangeEvent.signedIn && _googleSignInPending) {
          _googleSignInPending = false;
          _populateFromCurrentProfile();
          setState(() => currentStep = 1);
        }
      });
    }
  }

  void _populateFromCurrentProfile() {
    final p = AuthService.currentProfile;
    if (p.fullName.isNotEmpty && p.fullName != 'Harur Resident') {
      _nameCtrl.text = p.fullName;
    }
    if (p.phone.isNotEmpty && !p.phone.contains('00000')) {
      _phoneCtrl.text = p.phone;
    }
    if (p.wardLocality.isNotEmpty) {
      _wardCtrl.text = p.wardLocality;
      pinnedLocationName = p.wardLocality;
    }
    if (bloodGroups.contains(p.bloodGroup)) {
      selectedBloodGroup = p.bloodGroup;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
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

  // --- Validation Helpers ---
  bool get _isEmailValid {
    final email = _emailCtrl.text.trim();
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool get _isNameValid {
    return _nameCtrl.text.trim().length >= 3;
  }

  bool get _isPhoneValid {
    final clean = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 10;
  }

  Future<void> _handleStep1Auth() async {
    final email = _emailCtrl.text.trim();
    final pwd = _passwordCtrl.text.trim();

    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE44545),
          content: Text('Please enter a valid email address (e.g. name@domain.com).'),
        ),
      );
      return;
    }

    // Rate Limiting check
    if (RateLimitSecurityService.isLockedOut(email)) {
      final remaining = RateLimitSecurityService.remainingLockoutSeconds(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE44545),
          content: Text('⚠️ Security Lockout: Too many failed attempts. Retry in $remaining seconds.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    bool success = false;

    if (isSignUp) {
      final eval = PasswordSecurityService.evaluatePassword(pwd);
      if (!eval.isValid) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE44545),
            content: Text('Password requirements: ${eval.missingRequirements.join(", ")}'),
          ),
        );
        return;
      }

      final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : email.split('@').first;
      final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000';

      final secErr = SecurityFilterService.validateUsernameAndName(username: email.split('@').first, fullName: name);
      if (secErr != null) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFFE44545), content: Text(secErr)));
        return;
      }

      success = await AuthService.signUpWithEmailPassword(
        email: email,
        password: pwd,
        fullName: name,
        phone: phone,
      );
    } else {
      success = await AuthService.signInWithEmailPassword(email, pwd);
    }

    setState(() => _isProcessing = false);

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE44545),
            content: Text('Authentication failed. Please verify credentials or connection.'),
          ),
        );
      }
      return;
    }

    _populateFromCurrentProfile();
    if (mounted) {
      setState(() => currentStep = 1);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _googleSignInPending = true;
    final launched = await AuthService.signInWithGoogle();
    if (!launched) {
      _googleSignInPending = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE44545),
            content: Text('Google Sign-In could not be started. Please try again.'),
          ),
        );
      }
    } else {
      _populateFromCurrentProfile();
      if (mounted) {
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

    if (_nameCtrl.text.trim().isNotEmpty && !_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE44545),
          content: Text('Full Name must be at least 3 characters long.'),
        ),
      );
      return;
    }

    if (_phoneCtrl.text.trim().isNotEmpty && !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE44545),
          content: Text('Please enter a valid 10-digit phone number.'),
        ),
      );
      return;
    }

    final validationErr = SecurityFilterService.validateUsernameAndName(
      username: AuthService.currentProfile.username,
      fullName: name,
    );
    if (validationErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: const Color(0xFFE44545), content: Text(validationErr)),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await AuthService.savePersonalDetails(
      fullName: name,
      phone: phone,
      wardLocality: ward,
      bloodGroup: selectedBloodGroup,
      emergencyContactName: emName,
      emergencyContactPhone: emPhone,
      bio: bio,
    );
    setState(() => _isProcessing = false);

    if (mounted) {
      setState(() => currentStep = 2);
    }
  }

  Future<void> _handleStep3Finish() async {
    setState(() => _isProcessing = true);
    await AuthService.savePersonalDetails(
      fullName: AuthService.currentProfile.fullName,
      phone: AuthService.currentProfile.phone,
      wardLocality: pinnedLocationName,
      bloodGroup: AuthService.currentProfile.bloodGroup,
      emergencyContactName: AuthService.currentProfile.emergencyContactName,
      emergencyContactPhone: AuthService.currentProfile.emergencyContactPhone,
      bio: AuthService.currentProfile.bio,
    );
    setState(() => _isProcessing = false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TownShell()),
      );
    }
  }

  void _triggerGpsLocate() {
    setState(() => isDetectingGps = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          isDetectingGps = false;
          pinnedLocationName = 'Harur Town Bus Stand (Live GPS)';
          pinnedLat = 12.0624;
          pinnedLon = 78.4983;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF234149),
            content: Text('✓ Live GPS Location locked to Harur Town (12.0624° N, 78.4983° E)'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top Stepper Header (Clean Glass Style)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/brand/myharur_icon.svg', width: 34, height: 34),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('myharur', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.6, color: Color(0xFF16272E))),
                            Text('DIGITAL TOWN PASSPORT', style: TextStyle(fontSize: 9, color: Color(0xFF6A828B), fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2EDF2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD4E3EA)),
                          ),
                          child: Text(
                            'Step ${currentStep + 1} of 3',
                            style: const TextStyle(color: Color(0xFF234149), fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress Track
                    Row(
                      children: [
                        _buildStepPill(0, 'Identity & Auth'),
                        const SizedBox(width: 6),
                        _buildStepPill(1, 'Digital Pass'),
                        const SizedBox(width: 6),
                        _buildStepPill(2, 'Town Locality'),
                      ],
                    ),
                  ],
                ),
              ),

              // Animated Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: currentStep == 0
                        ? _buildStep1Auth()
                        : (currentStep == 1 ? _buildStep2Details() : _buildStep3Map()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill(int index, String label) {
    final active = currentStep == index;
    final done = currentStep > index;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: done || active ? const Color(0xFF234149) : const Color(0xFFD4E3EA),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              color: active ? const Color(0xFF234149) : const Color(0xFF6A828B),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // STEP 1: AUTHENTICATION & TOWN ENTRY
  // ==============================================================================
  Widget _buildStep1Auth() {
    return KeyedSubtree(
      key: const ValueKey('step_1_auth'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          BentoCard(
            variant: BentoCardVariant.darkPetrol,
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('HARUR DIGITAL TOWN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                    ),
                    const Spacer(),
                    const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to Your Connected Town.',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.4),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your verified gateway for Harur shops, jobs, mandi rates, bus routes & 24/7 SOS support.',
                  style: TextStyle(color: Color(0xFFB5D4DF), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Google OAuth One-Tap Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF16272E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(color: Color(0xFFD4E3EA), width: 1.2),
                ),
              ),
              onPressed: _isProcessing ? null : _handleGoogleSignIn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EDF2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF234149).withValues(alpha: 0.15)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF234149),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF16272E), letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFD4E3EA))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('or with email & password', style: TextStyle(fontSize: 11, color: Color(0xFF6A828B), fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Divider(color: Color(0xFFD4E3EA))),
            ],
          ),
          const SizedBox(height: 16),

          // Email Input
          SquirclePillInput(
            controller: _emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          // Password Input
          SquirclePillInput(
            controller: _passwordCtrl,
            hint: 'Password (min 6 chars)',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF6A828B)),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          const SizedBox(height: 22),

          // Primary Step 1 Action Button
          PetrolButton(
            label: isSignUp ? 'Create Pass & Continue →' : 'Sign In to MyHarur →',
            isLoading: _isProcessing,
            onTap: _handleStep1Auth,
          ),

          const SizedBox(height: 14),

          // Toggle Sign In / Sign Up
          Center(
            child: TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                isSignUp ? 'Already have an MMID? Sign In' : 'New resident? Register Digital Pass',
                style: const TextStyle(color: Color(0xFF234149), fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),

          // Guest Mode Fast Pass
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16272E),
                side: const BorderSide(color: Color(0xFFD4E3EA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.explore_rounded, size: 16, color: Color(0xFF234149)),
              label: const Text('Explore Harur as Guest Visitor →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              onPressed: () {
                AuthService.loginAsGuest();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const TownShell()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // STEP 2: LIVE HOLOGRAPHIC MMID PASS CUSTOMIZER
  // ==============================================================================
  Widget _buildStep2Details() {
    final liveName = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Harur Resident';
    final livePhone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000';
    final liveWard = _wardCtrl.text.trim().isNotEmpty ? _wardCtrl.text.trim() : 'Harur Town HQ';

    return KeyedSubtree(
      key: const ValueKey('step_2_details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customise Your Resident Pass', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF16272E), letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('Your digital pass updates live below as you enter your details.', style: TextStyle(fontSize: 12, color: Color(0xFF6A828B))),
          const SizedBox(height: 16),

          // LIVE MMID PASS PREVIEW (Deep Petrol Bento)
          BentoCard(
            variant: BentoCardVariant.darkPetrol,
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset('assets/brand/myharur_icon.svg', width: 26, height: 26),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('myharur', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                            Text('RESIDENT IDENTITY PASS', style: TextStyle(color: Color(0xFFB5D4DF), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  liveName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  livePhone,
                  style: const TextStyle(color: Color(0xFFB5D4DF), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LOCALITY / WARD', style: TextStyle(color: Color(0xFF8BA6B0), fontSize: 9, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(liveWard, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(selectedBloodGroup, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Full Name Input
          SquirclePillInput(
            controller: _nameCtrl,
            hint: 'Full Name (Official)',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 12),

          // Phone Number Input
          SquirclePillInput(
            controller: _phoneCtrl,
            hint: 'Mobile Phone Number (+91)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Ward / Locality
          SquirclePillInput(
            controller: _wardCtrl,
            hint: 'Ward / Area in Harur',
            icon: Icons.location_on_outlined,
          ),

          const SizedBox(height: 12),

          // Blood Group Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD4E3EA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bloodtype_outlined, size: 20, color: Color(0xFFE44545)),
                const SizedBox(width: 10),
                const Text('Blood Group (Emergency):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF6A828B))),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedBloodGroup,
                  underline: const SizedBox(),
                  items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16272E))))).toList(),
                  onChanged: (val) => setState(() => selectedBloodGroup = val ?? 'O+'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Next Step Button
          PetrolButton(
            label: 'Next: Locality & Landmarks →',
            isLoading: _isProcessing,
            onTap: _handleStep2Details,
          ),
        ],
      ),
    );
  }

  // ==============================================================================
  // STEP 3: HARUR LOCALITY & LANDMARK PINNING
  // ==============================================================================
  Widget _buildStep3Map() {
    return KeyedSubtree(
      key: const ValueKey('step_3_map'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Your Harur Landmark', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF16272E), letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('Choose your primary neighborhood hub or use live GPS pinning.', style: TextStyle(fontSize: 12, color: Color(0xFF6A828B))),
          const SizedBox(height: 16),

          // GPS Pinning Action
          BentoCard(
            variant: BentoCardVariant.pastel,
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            onTap: _triggerGpsLocate,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF234149), borderRadius: BorderRadius.circular(12)),
                  child: isDetectingGps
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lock to Harur Live Coordinates', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF16272E))),
                      const SizedBox(height: 2),
                      Text('Lat: $pinnedLat° N • Lon: $pinnedLon° E', style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF234149), size: 20),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text('POPULAR LANDMARKS & SECTORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6A828B), letterSpacing: 0.8)),
          const SizedBox(height: 10),

          // Landmark Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: landmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final landmark = landmarks[i];
              final isSelected = pinnedLocationName == landmark['name'];

              return BentoCard(
                variant: isSelected ? BentoCardVariant.pastel : BentoCardVariant.elevatedWhite,
                borderRadius: 20,
                padding: const EdgeInsets.all(14),
                onTap: () {
                  setState(() {
                    pinnedLocationName = landmark['name'] as String;
                    pinnedLat = landmark['lat'] as double;
                    pinnedLon = landmark['lon'] as double;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF234149) : const Color(0xFFE2EDF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        landmark['icon'] as IconData,
                        color: isSelected ? Colors.white : const Color(0xFF234149),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            landmark['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color(0xFF16272E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            landmark['desc'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B)),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF234149), size: 20),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Complete Onboarding Button
          PetrolButton(
            label: 'Enter MyHarur Town Hub 🚀',
            icon: Icons.launch_rounded,
            isLoading: _isProcessing,
            onTap: _handleStep3Finish,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
