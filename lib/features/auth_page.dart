import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/supabase_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignUp = false;
  bool isOfficialMode = false;
  bool isEditingDetails = false;

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

  @override
  void initState() {
    super.initState();
    _populateProfileData();
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

  Future<void> _handleGoogleSignIn() async {
    final success = await AuthService.signInWithGoogle();
    if (mounted) {
      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF007F63),
            content: Text('✓ Signed in with Google OAuth. Verified Resident profile active.'),
          ),
        );
      }
    }
  }

  Future<void> _handleAuthAction() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    if (isSignUp) {
      final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Harur Resident';
      final phone = _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98420 11000';
      await AuthService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF007F63),
            content: Text('✓ Account created! Your MMID: ${AuthService.currentProfile.mmid}'),
          ),
        );
      }
    } else {
      final ok = await AuthService.signInWithEmailPassword(email, password);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF007F63),
            content: Text(ok ? '✓ Logged in as ${AuthService.currentProfile.fullName} (${AuthService.currentProfile.role.toUpperCase()})' : 'Login failed. Please check credentials.'),
          ),
        );
      }
    }
  }

  Future<void> _savePersonalDetails() async {
    await AuthService.savePersonalDetails(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      wardLocality: _wardCtrl.text.trim(),
      bloodGroup: selectedBloodGroup,
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => isEditingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF007F63),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isLoggedIn ? 'Resident Profile & Security' : 'MyHarur Account',
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isLoggedIn)
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE44545)),
              onPressed: () async {
                await AuthService.signOut();
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
    );
  }

  Widget _buildLoggedInView(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Profile Card with MMID & Role
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF15211F), Color(0xFF070B0A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007F63).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D09C).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00D09C), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'H',
                        style: const TextStyle(color: Color(0xFF00D09C), fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D09C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profile.role.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF070B0A), fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MMID: ${profile.mmid}',
                              style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBadge(Icons.location_on_rounded, profile.wardLocality),
                  _buildStatBadge(Icons.bloodtype_rounded, profile.bloodGroup),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Personal Details Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PERSONAL DETAILS & RECOVERY',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF697570), letterSpacing: 1.1),
            ),
            TextButton.icon(
              icon: Icon(isEditingDetails ? Icons.close_rounded : Icons.edit_rounded, size: 16, color: const Color(0xFF007F63)),
              label: Text(isEditingDetails ? 'Cancel' : 'Edit', style: const TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800)),
              onPressed: () => setState(() => isEditingDetails = !isEditingDetails),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (isEditingDetails) ...[
          // Editable Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormInput('Full Name', _nameCtrl, Icons.person_rounded),
                const SizedBox(height: 14),
                _buildFormInput('Phone Number', _phoneCtrl, Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormInput('Ward / Area in Harur', _wardCtrl, Icons.pin_drop_rounded),
                const SizedBox(height: 14),
                const Text('Blood Group (For Emergency Aid)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF697570))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBloodGroup,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (val) => setState(() => selectedBloodGroup = val ?? 'O+'),
                ),
                const SizedBox(height: 14),
                _buildFormInput('Emergency Contact Name', _emergencyNameCtrl, Icons.contact_emergency_rounded),
                const SizedBox(height: 14),
                _buildFormInput('Emergency Contact Phone', _emergencyPhoneCtrl, Icons.phone_callback_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormInput('Bio / Occupation', _bioCtrl, Icons.badge_rounded, maxLines: 2),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007F63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Save & Sync to Ledger', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: _savePersonalDetails,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Readonly Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2EBE8)),
            ),
            child: Column(
              children: [
                _buildDetailRow(Icons.email_rounded, 'Email Address', profile.email),
                const Divider(height: 22),
                _buildDetailRow(Icons.phone_rounded, 'Phone Number', profile.phone),
                const Divider(height: 22),
                _buildDetailRow(Icons.home_rounded, 'Ward / Locality', profile.wardLocality),
                const Divider(height: 22),
                _buildDetailRow(Icons.bloodtype_rounded, 'Blood Group', profile.bloodGroup),
                const Divider(height: 22),
                _buildDetailRow(Icons.contact_emergency_rounded, 'Emergency Contact', '${profile.emergencyContactName} (${profile.emergencyContactPhone})'),
                const Divider(height: 22),
                _buildDetailRow(Icons.info_outline_rounded, 'Bio / Occupation', profile.bio),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Password & Security Management
        const Text(
          'PASSWORD & SECURITY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF697570), letterSpacing: 1.1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF007F63)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (_newPasswordCtrl.text.trim().isNotEmpty) {
                      await AuthService.changePassword(_newPasswordCtrl.text.trim());
                      _newPasswordCtrl.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated successfully!')),
                        );
                      }
                    }
                  },
                  child: const Text('Change Password', style: TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6F1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/brand/myharur_icon.svg',
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            isOfficialMode
                ? 'SuperAdmin & Official Login'
                : (isSignUp ? 'Create Resident Account' : 'Welcome to MyHarur'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            isOfficialMode
                ? 'Chief administration credentials with root consensus'
                : 'Protected with Argon2id & immutable town ledger',
            style: const TextStyle(fontSize: 12, color: Color(0xFF697570)),
          ),
        ),
        const SizedBox(height: 28),

        // Quick Google OAuth Button (For Residents)
        if (!isOfficialMode) ...[
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
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or with email & MMID', style: TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // Input Fields
        if (isSignUp) ...[
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name',
              filled: true,
              fillColor: const Color(0xFFF2F6F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            filled: true,
            fillColor: const Color(0xFFF2F6F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007F63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _handleAuthAction,
            child: Text(
              isSignUp ? 'Create Account & Generate MMID' : 'Sign In',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Toggle Sign Up / Sign In
        if (!isOfficialMode) ...[
          Center(
            child: TextButton(
              onPressed: () => setState(() => isSignUp = !isSignUp),
              child: Text(
                isSignUp ? 'Already have an MMID? Sign In' : 'New resident? Create Account & MMID',
                style: const TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

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
                color: isOfficialMode ? const Color(0xFF697570) : const Color(0xFF267AF4),
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00D09C), size: 14),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF697570))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF007F63), size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF007F63), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value.isNotEmpty ? value : 'Not set', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF15211F))),
            ],
          ),
        ),
      ],
    );
  }
}
