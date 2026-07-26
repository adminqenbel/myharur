import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isAdminMode = false;

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
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
      _showError('Sign-In Error: $e');
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
      _showError('Login failed. Check credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 24),
              Text('Welcome to MyHarur',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              Text('Your Hyperlocal Town App',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!_isAdminMode) ...[
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.account_circle, size: 24),
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ApiClient.clearToken();
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Browse as Guest'),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => setState(() => _isAdminMode = true),
                  child: const Text('Admin / Staff Login', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ] else ...[
                Text('Admin Login', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleAdminLogin,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () => setState(() => _isAdminMode = false),
                  child: const Text('← Back to User Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
