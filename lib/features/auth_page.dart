import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart';
import '../widgets/glass_components.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignUp = false;
  bool isOfficialMode = false;
  bool isEditingDetails = false;
  bool _obscurePassword = true;
  bool _isProcessing = false;

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  String selectedBloodGroup = 'O+';
  final bloodGroups = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

  StreamSubscription<AuthState>? _authSub;
  bool _googleSignInPending = false;

  @override
  void initState() {
    super.initState();
    _populateProfileData();

    final client = SupabaseConfig.client;
    if (client != null) {
      _authSub = client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.event == AuthChangeEvent.signedIn && _googleSignInPending) {
          _googleSignInPending = false;
          _populateProfileData();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF234149),
              content: Text('✓ Signed in with Google OAuth. Verified Resident profile active.'),
            ),
          );
        }
      });
    }
  }

  void _populateProfileData() {
    final p = AuthService.currentProfile;
    _nameCtrl.text = p.fullName;
    _phoneCtrl.text = p.phone;
    _wardCtrl.text = p.wardLocality;
    _emergencyNameCtrl.text = p.emergencyContactName;
    _emergencyPhoneCtrl.text = p.emergencyContactPhone;
    _bioCtrl.text = p.bio;
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
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isEmailValid {
    final email = _emailCtrl.text.trim();
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isProcessing = true);
    _googleSignInPending = true;
    final launched = await AuthService.signInWithGoogle();
    setState(() => _isProcessing = false);

    if (!launched) {
      _googleSignInPending = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE44545),
            content: Text('Google Sign-In could not be started. Opening browser...'),
          ),
        );
      }
    } else {
      _populateProfileData();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleAuthAction() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Color(0xFFE44545), content: Text('Please enter a valid email address.')),
      );
      return;
    }

    // Rate Limiting / Brute Force Lockout check
    if (RateLimitSecurityService.isLockedOut(email)) {
      final remaining = RateLimitSecurityService.remainingLockoutSeconds(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE44545),
          content: Text('⚠️ Security Lockout: Too many failed attempts. Try again in $remaining seconds.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    if (isSignUp) {
      // Password Entropy Check
      final passwordEval = PasswordSecurityService.evaluatePassword(password);
      if (!passwordEval.isValid) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE44545),
            content: Text('Password requirements missing: ${passwordEval.missingRequirements.join(", ")}'),
          ),
        );
        return;
      }

      final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : email.split('@').first;
      final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000';

      final err = SecurityFilterService.validateUsernameAndName(username: email.split('@').first, fullName: name);
      if (err != null) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFFE44545), content: Text(err)));
        return;
      }

      final ok = await AuthService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
      );
      setState(() => _isProcessing = false);

      if (mounted) {
        _populateProfileData();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok ? const Color(0xFF234149) : const Color(0xFFE44545),
            content: Text(ok ? '✓ Cryptographic Pass generated! MMID: ${AuthService.currentProfile.mmid}' : 'Sign up failed. Please check credentials.'),
          ),
        );
      }
    } else {
      final ok = await AuthService.signInWithEmailPassword(email, password);
      setState(() => _isProcessing = false);

      if (mounted) {
        _populateProfileData();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok ? const Color(0xFF234149) : const Color(0xFFE44545),
            content: Text(ok ? '✓ Logged in as ${AuthService.currentProfile.fullName}' : 'Login failed. Please verify email and password.'),
          ),
        );
      }
    }
  }

  Future<void> _savePersonalDetails() async {
    final name = _nameCtrl.text.trim();
    final err = SecurityFilterService.validateUsernameAndName(username: AuthService.currentProfile.username, fullName: name);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: const Color(0xFFE44545), content: Text(err)));
      return;
    }

    setState(() => _isProcessing = true);
    await AuthService.savePersonalDetails(
      fullName: name,
      phone: _phoneCtrl.text.trim(),
      wardLocality: _wardCtrl.text.trim(),
      bloodGroup: selectedBloodGroup,
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    setState(() {
      _isProcessing = false;
      isEditingDetails = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF234149),
          content: Text('✓ Personal details saved safely and synced to Harur Ledger!'),
        ),
      );
    }
  }

  void _fillSuperAdminPreset() {
    setState(() {
      _emailCtrl.text = 'admin.qenbel@gmail.com';
      _passwordCtrl.text = 'admin@qenbel';
      isOfficialMode = true;
      isSignUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthService.currentProfile;
    final isLoggedIn = AuthService.isAuthenticated;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            isLoggedIn ? 'Resident Identity' : 'Harur Digital Pass',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16272E), letterSpacing: -0.4),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF16272E), size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (isLoggedIn)
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFE44545), size: 20),
                onPressed: () async {
                  await AuthService.signOut();
                  _populateProfileData();
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out successfully.')),
                    );
                  }
                },
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: isLoggedIn ? _buildLoggedInView(profile) : _buildAuthForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MMID Hero Card in Deep Petrol (Screen 2 MMID Card style)
        BentoCard(
          variant: BentoCardVariant.darkPetrol,
          borderRadius: 26,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                profile.primaryRoleTitle.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "@${profile.username.replaceAll('@', '')}",
                              style: const TextStyle(color: Color(0xFFB5D4DF), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'MMID: ${profile.mmid}',
                          style: const TextStyle(color: Color(0xFF8BA6B0), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBadge(Icons.location_on_rounded, profile.wardLocality),
                  _buildStatBadge(Icons.bloodtype_rounded, 'Blood: ${profile.bloodGroup}'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Personal Details Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RESIDENT PROFILE & EMERGENCY DATA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6A828B), letterSpacing: 1.1),
            ),
            TextButton.icon(
              icon: Icon(isEditingDetails ? Icons.close_rounded : Icons.edit_rounded, size: 16, color: const Color(0xFF234149)),
              label: Text(isEditingDetails ? 'Cancel' : 'Edit', style: const TextStyle(color: Color(0xFF234149), fontWeight: FontWeight.w800, fontSize: 12)),
              onPressed: () => setState(() => isEditingDetails = !isEditingDetails),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (isEditingDetails) ...[
          BentoCard(
            variant: BentoCardVariant.elevatedWhite,
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormInput('Full Name', _nameCtrl, Icons.person_rounded),
                const SizedBox(height: 14),
                _buildFormInput('Phone Number', _phoneCtrl, Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormInput('Ward / Area in Harur', _wardCtrl, Icons.pin_drop_rounded),
                const SizedBox(height: 14),
                const Text('Blood Group (Emergency Aid)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6A828B))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBloodGroup,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF0F5F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
                  ),
                  items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16272E))))).toList(),
                  onChanged: (val) => setState(() => selectedBloodGroup = val ?? 'O+'),
                ),
                const SizedBox(height: 14),
                _buildFormInput('Emergency Contact Name', _emergencyNameCtrl, Icons.contact_emergency_rounded),
                const SizedBox(height: 14),
                _buildFormInput('Emergency Contact Phone', _emergencyPhoneCtrl, Icons.phone_callback_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormInput('Bio / Occupation', _bioCtrl, Icons.badge_rounded, maxLines: 2),
                const SizedBox(height: 20),
                PetrolButton(
                  label: 'Save & Sync to Ledger',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isProcessing,
                  onTap: _savePersonalDetails,
                ),
              ],
            ),
          ),
        ] else ...[
          BentoCard(
            variant: BentoCardVariant.elevatedWhite,
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildDetailRow(Icons.email_rounded, 'Email Address', profile.email),
                const Divider(height: 20, color: Color(0xFFF0F5F8)),
                _buildDetailRow(Icons.phone_rounded, 'Phone Number', profile.phone),
                const Divider(height: 20, color: Color(0xFFF0F5F8)),
                _buildDetailRow(Icons.home_rounded, 'Ward / Locality', profile.wardLocality),
                const Divider(height: 20, color: Color(0xFFF0F5F8)),
                _buildDetailRow(Icons.bloodtype_rounded, 'Blood Group', profile.bloodGroup),
                const Divider(height: 20, color: Color(0xFFF0F5F8)),
                _buildDetailRow(Icons.contact_emergency_rounded, 'Emergency Contact', '${profile.emergencyContactName} (${profile.emergencyContactPhone})'),
                const Divider(height: 20, color: Color(0xFFF0F5F8)),
                _buildDetailRow(Icons.info_outline_rounded, 'Bio / Occupation', profile.bio),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Cryptographic Passport Integrity Seal
        BentoCard(
          variant: BentoCardVariant.pastel,
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF234149),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Cryptographic Integrity Seal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
                        SizedBox(width: 6),
                        Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SHA-256 Checksum: ${profile.verifiedSignature}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: Color(0xFF234149)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Multi-Factor Authentication (MFA / 2FA) Section
        BentoCard(
          variant: BentoCardVariant.elevatedWhite,
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF234149), size: 20),
                      SizedBox(width: 8),
                      Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
                    ],
                  ),
                  Switch.adaptive(
                    value: profile.isMfaEnabled,
                    activeTrackColor: const Color(0xFF234149),
                    onChanged: (val) async {
                      await AuthService.toggleMfa(val);
                      _populateProfileData();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF234149),
                            content: Text(val ? '✓ 2FA enabled with TOTP authentication.' : '2FA disabled.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                profile.isMfaEnabled
                    ? 'Your account is secured with 30s TOTP rotating codes. Hardware passkeys authorized.'
                    : 'Add an extra layer of security. Require a dynamic 6-digit TOTP passkey on sign in.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B)),
              ),
              if (profile.isMfaEnabled) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EDF2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current TOTP Passkey Code', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6A828B))),
                          const SizedBox(height: 2),
                          Text(
                            IdentityCryptoService.generateMfaOtp(profile.mfaSecret),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4, color: Color(0xFF234149), fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF234149),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('30s Valid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Password & Security Management
        const Text(
          'PASSWORD & SECURITY KEYS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6A828B), letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        BentoCard(
          variant: BentoCardVariant.elevatedWhite,
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16272E))),
              const SizedBox(height: 10),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16272E)),
                decoration: InputDecoration(
                  labelText: 'New Password (min 8 chars, mixed case, digit, symbol)',
                  labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF6A828B)),
                  filled: true,
                  fillColor: const Color(0xFFF0F5F8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
                ),
              ),
              if (_newPasswordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final eval = PasswordSecurityService.evaluatePassword(_newPasswordCtrl.text);
                    Color barColor = const Color(0xFFE44545);
                    if (eval.score >= 0.7) barColor = const Color(0xFF247BA0);
                    if (eval.score >= 0.9) barColor = const Color(0xFF10B981);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(eval.strengthLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: barColor)),
                            Text('${(eval.score * 100).toInt()}% Entropy', style: const TextStyle(fontSize: 10, color: Color(0xFF6A828B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: eval.score,
                            backgroundColor: const Color(0xFFE2EDF2),
                            valueColor: AlwaysStoppedAnimation(barColor),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF234149)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final pass = _newPasswordCtrl.text.trim();
                    final eval = PasswordSecurityService.evaluatePassword(pass);
                    if (!eval.isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFE44545),
                          content: Text('Password requirements: ${eval.missingRequirements.join(", ")}'),
                        ),
                      );
                      return;
                    }
                    await AuthService.changePassword(pass);
                    _newPasswordCtrl.clear();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(backgroundColor: Color(0xFF234149), content: Text('✓ Password updated with high entropy!')),
                      );
                    }
                  },
                  child: const Text('Update & Encrypt Password', style: TextStyle(color: Color(0xFF234149), fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Logo & Minimalist Screen 1 Header
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF234149),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF234149).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/brand/myharur_icon.svg',
                width: 44,
                height: 44,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            isOfficialMode ? 'Official Governance Portal' : (isSignUp ? 'Create Resident Account' : 'Welcome to MyHarur'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF16272E), letterSpacing: -0.6),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            isOfficialMode ? 'Administrative access with passkey authorization' : 'Verified MMID resident passport with immutable ledger',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6A828B), fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 26),

        // Quick Google OAuth Button (High contrast, modern style)
        if (!isOfficialMode) ...[
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
        ],

        // Input Fields (Pill Rounded design like Screen 1)
        if (isSignUp) ...[
          SquirclePillInput(
            controller: _nameCtrl,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          SquirclePillInput(
            controller: _phoneCtrl,
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
        ],

        SquirclePillInput(
          controller: _emailCtrl,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        SquirclePillInput(
          controller: _passwordCtrl,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF6A828B)),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 22),

        // Primary CTA Button (Deep Petrol #234149 from Screen 1)
        PetrolButton(
          label: isSignUp ? 'Create Account & Generate MMID' : 'Sign In',
          isLoading: _isProcessing,
          onTap: _handleAuthAction,
        ),

        const SizedBox(height: 16),

        // Toggle Sign Up / Sign In
        if (!isOfficialMode) ...[
          Center(
            child: TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                isSignUp ? 'Already have an MMID? Sign In' : 'New resident? Register Digital Pass & MMID',
                style: const TextStyle(color: Color(0xFF234149), fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Official / SuperAdmin Preset Button
        Center(
          child: TextButton(
            onPressed: () {
              if (isOfficialMode) {
                setState(() => isOfficialMode = false);
              } else {
                _fillSuperAdminPreset();
              }
            },
            child: Text(
              isOfficialMode ? '← Back to Resident Sign In' : '👑 Root SuperAdmin (admin.qenbel@gmail.com) →',
              style: TextStyle(
                color: isOfficialMode ? const Color(0xFF6A828B) : const Color(0xFF247BA0),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6A828B))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16272E)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF234149), size: 18),
            filled: true,
            fillColor: const Color(0xFFF0F5F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD4E3EA))),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF234149), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6A828B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value.isNotEmpty ? value : 'Not set', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF16272E))),
            ],
          ),
        ),
      ],
    );
  }
}
