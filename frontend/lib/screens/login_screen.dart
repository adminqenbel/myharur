import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isAdminMode = false;
  bool _obscurePwd = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSuccess(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final user = data['user'] as Map<String, dynamic>? ?? {};
    await ref.read(authProvider.notifier).loginWithToken(token, user);
    if (!mounted) return;
    final isSetup = ref.read(authProvider).isSetupComplete;
    context.go(isSetup ? '/home' : '/onboarding');
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '976428818123-neqkk6i6n7akahbjdcfnf568dk9lku0k.apps.googleusercontent.com',
      );
      await googleSignIn.signOut(); // force account picker
      final account = await googleSignIn.signIn();
      if (account != null && mounted) {
        final response = await ApiClient.dio.post('/auth/google', data: {
          'email': account.email,
          'first_name': account.displayName?.split(' ').first ?? 'User',
          'last_name': account.displayName?.split(' ').skip(1).join(' ') ?? '',
          'photo_url': account.photoUrl,
        });
        await _handleSuccess(response.data);
      }
    } catch (e) {
      _showError('Sign-In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {'username': email, 'password': password},
      );
      await _handleSuccess(response.data);
    } catch (e) {
      _showError('Login failed. Check your credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),

              Text('Welcome to MyHarur',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Your Hyperlocal Town Super App',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 48),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                )
              else if (!_isAdminMode) ...[
                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.divider, width: 1.5),
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Logo SVG replacement
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                          child: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
                        ),
                        const SizedBox(width: 10),
                        Text('Continue with Google',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Guest
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Browse as Guest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                Row(children: [
                  const Expanded(child: Divider()), 
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: Theme.of(context).textTheme.bodySmall)),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () => setState(() => _isAdminMode = true),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: const Text('Admin / Staff Login'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                ),

              ] else ...[
                // Admin Login Card
                Container(
                  decoration: AppTheme.card(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text('Admin Login', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                        ),
                        obscureText: _obscurePwd,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleAdminLogin,
                          child: const Text('Login', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => setState(() => _isAdminMode = false),
                  icon: const Icon(Icons.arrow_back_ios, size: 14),
                  label: const Text('Back to User Login'),
                ),
              ],

              const SizedBox(height: 40),
              Text('© 2026 MyHarur • Powered by Qenbel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
