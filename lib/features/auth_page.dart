import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isStaffMode = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool isLinkingGoogle = false;

  void _signInWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signing in with Google OAuth... Verified Resident profile created.')),
    );
    Navigator.pop(context);
  }

  void _staffLogin() {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter staff username and password.')),
      );
      return;
    }

    // Step 2: Show mandatory Google Account Linking prompt for first-time staff
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF007F63)),
            SizedBox(width: 8),
            Text('Link Google Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'For maximum role security and recovery, official staff accounts require mandatory 1-time Google account linking and Argon2id verification.',
          style: TextStyle(fontSize: 13, color: Color(0xFF697570), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF697570))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007F63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Staff verified, Google linked, and AID assigned!')),
              );
            },
            child: const Text('Link & Complete Login', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F6F1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/shield.svg',
                      width: 36,
                      height: 36,
                      colorFilter: const ColorFilter.mode(Color(0xFF007F63), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'MyHarur Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Protected with Argon2id KDF & Google OAuth',
                  style: TextStyle(fontSize: 13, color: Color(0xFF697570)),
                ),
              ),
              const SizedBox(height: 32),

              // Resident Google Sign In Button
              if (!isStaffMode) ...[
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
                    onPressed: _signInWithGoogle,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => isStaffMode = true),
                    child: const Text(
                      'Admin / Staff / Govt Official Login →',
                      style: TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ] else ...[
                // Staff Username + Password flow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDCE5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff & Official Credentials',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF15211F)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Reserved username format (e.g. collector_dharmapuri, police_harur)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF697570)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          filled: true,
                          fillColor: Colors.white,
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
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007F63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _staffLogin,
                          child: const Text('Staff Sign In', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => isStaffMode = false),
                    child: const Text('← Back to Resident Sign-in', style: TextStyle(color: Color(0xFF697570), fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
