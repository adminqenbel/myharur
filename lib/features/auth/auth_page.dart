import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==============================================================================
// AUTH PAGE â€” Google OAuth + Email/Password (staff)
// Shown when the user is not authenticated.
// After auth, onboarding_state is checked to route to the correct step.
// ==============================================================================
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePw = true;
  bool _processing = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  StreamSubscription<AuthState>? _authSub;
  bool _googlePending = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Listen for Google OAuth callback
    final client = SupabaseConfig.client;
    if (client != null) {
      _authSub = client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        if (data.event == AuthChangeEvent.signedIn && _googlePending) {
          _googlePending = false;
          // AuthService.init() listener handles the rest
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    setState(() { _processing = true; _error = null; _googlePending = true; });
    final ok = await AuthService.signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      setState(() { _processing = false; _error = 'Google sign-in could not be launched. Check your connection.'; _googlePending = false; });
    }
    // If ok, we wait for the auth state listener to fire
    setState(() => _processing = false);
  }

  Future<void> _handleEmailAction() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() { _processing = true; _error = null; });

    bool ok;
    if (_isSignUp) {
      ok = await AuthService.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: 'Harur Resident',
      );
    } else {
      ok = await AuthService.signInWithEmailPassword(email, password);
    }

    if (!mounted) return;
    setState(() => _processing = false);

    if (!ok) {
      setState(() => _error = _isSignUp
          ? 'Sign-up failed. Email may already be registered or password too weak.'
          : 'Sign-in failed. Check your email and password.');
    }
    // On success AuthService.init() listener handles routing
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = SupabaseConfig.isConfigured;

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: AtmosphericBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Logo / Brand
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.location_city_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'MyHarur',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.largeTitle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Harur & Dharmapuri\'s digital town platform',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.footnote,
                      ),
                      const SizedBox(height: 40),

                      // Backend not configured warning
                      if (!isConfigured) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              'Running without backend connection. Auth unavailable.',
                              style: AppTextStyles.caption1.copyWith(color: AppColors.warning),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Google Sign-In button
                      _GoogleSignInButton(
                        onPressed: isConfigured ? _handleGoogle : null,
                        loading: _processing && _googlePending,
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or staff login', style: AppTextStyles.caption1),
                        ),
                        const Expanded(child: Divider()),
                      ]),

                      const SizedBox(height: 20),

                      // Email / Password (staff only)
                      GlassCard(
                        fillColor: Colors.white.withValues(alpha: 0.92),
                        blurSigma: 16,
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                                labelText: 'Staff Email',
                                hintText: 'name@qenbel.com',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePw,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePw ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(_error!, style: AppTextStyles.caption1.copyWith(color: AppColors.danger)),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isConfigured && !(_processing && _googlePending)
                                  ? _handleEmailAction
                                  : null,
                              child: _processing && !_googlePending
                                  ? const SizedBox(height: 18, width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(_isSignUp ? 'Already have an account? Sign In' : 'New here? Create Account'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'A QenBel product • Powered by Supabase',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption2,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Google Sign-In Button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const _GoogleSignInButton({this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.separator),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Google G icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: AppTextStyles.headline.copyWith(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

