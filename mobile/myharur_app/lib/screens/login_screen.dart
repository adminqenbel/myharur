import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../utils/update_manager.dart';
import '../theme.dart';
import '../widgets/design_system.dart';
import '../config/test_config.dart';

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
  final _accessCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _accessCodeFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateManager.checkUpdate(context);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _accessCodeController.dispose();
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
    final auth = ref.read(authProvider);
    if (auth.usernameRequired) {
      context.go('/username-setup');
    } else if (!auth.isSetupComplete) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (TestConfig.isLuxuryUiTestBuild) return;
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
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
      if (e is DioException && e.response != null && e.response?.data != null) {
        _showError('Server Error: ${e.response?.data['detail'] ?? e.response?.data}');
      } else {
        _showError('Sign-In failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccessCodeLogin() async {
    if (!_accessCodeFormKey.currentState!.validate()) return;
    final code = _accessCodeController.text.trim();
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post(
        '/access-codes/login',
        data: {'code': code},
      );
      await _handleSuccess(response.data);
    } catch (e) {
      if (e is DioException && e.response != null && e.response?.data != null) {
        _showError('Access code invalid: ${e.response?.data['detail'] ?? e.response?.data}');
      } else {
        _showError('Access Code Login failed. Check your testing code.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {'username': email, 'password': password},
      );
      await _handleSuccess(response.data);
    } catch (e) {
      if (e is DioException && e.response != null && e.response?.data != null) {
        _showError('Login failed: ${e.response?.data['detail'] ?? e.response?.data}');
      } else {
        _showError('Login failed. Check your credentials.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTest = TestConfig.isLuxuryUiTestBuild;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
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
                      color: Theme.of(context).colorScheme.surface,
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
                  Text(isTest ? 'Alpha Testing Channel (Luxury UI Build)' : 'Your Hyperlocal Town Super App',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isTest ? AppTheme.primary : null,
                        fontWeight: isTest ? FontWeight.w600 : null,
                      )),
                  const SizedBox(height: 36),

                  if (!isTest) ...[
                    // Standard Google Sign-In for Production
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.divider, width: 1.5),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, color: AppTheme.danger, size: 28),
                            const SizedBox(width: 10),
                            Text('Continue with Google', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    // TEST BUILD: Beta / Alpha Access Code Form
                    if (!_isAdminMode) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Form(
                          key: _accessCodeFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.vpn_key_rounded, color: Color(0xFF00E5FF), size: 20),
                                  const SizedBox(width: 8),
                                  Text('Tester Access Code Login',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Enter your generated testing code to start session.',
                                  style: TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _accessCodeController,
                                decoration: InputDecoration(
                                  hintText: 'e.g. ALPHA-984A',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.code, color: Color(0xFF00E5FF), size: 20),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                ),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                textCapitalization: TextCapitalization.characters,
                                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter access code' : null,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _handleAccessCodeLogin,
                                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                                  label: const Text('AUTHENTICATE TESTER CODE', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDD0200),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],

                  if (!_isAdminMode) ...[
                    // Browse as Guest
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).loginAsGuest();
                          if (context.mounted) {
                            context.go(isTest ? '/luxury' : '/home');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                          foregroundColor: isDark ? Colors.white : Colors.black,
                        ),
                        child: const Text('Browse as Guest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(children: const [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),

                    TextButton.icon(
                      onPressed: () => setState(() => _isAdminMode = true),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                      label: const Text('Super Admin / Staff Login'),
                      style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87),
                    ),

                  ] else ...[
                    // Admin Login Card
                    Container(
                      decoration: AppTheme.card(),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Admin Login', style: Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'Username or Email', prefixIcon: Icon(Icons.person_outline, size: 18)),
                              keyboardType: TextInputType.text,
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required field' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
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
                              validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: MHButton(
                                onPressed: _handleAdminLogin,
                                text: 'Login',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _isAdminMode = false),
                      icon: const Icon(Icons.arrow_back_ios, size: 14),
                      label: const Text('Back to Tester Access Code Login'),
                    ),
                  ],

                  const SizedBox(height: 40),
                  Text('© 2026 MyHarur • Powered by Qenbel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
