import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '976428818123-neqkk6i6n7akahbjdcfnf568dk9lku0k.apps.googleusercontent.com',
      );
      final account = await googleSignIn.signIn();
      if (account != null) {
        final response = await ApiClient.dio.post('/auth/google', data: {
          'email': account.email,
          'first_name': account.displayName?.split(' ').first ?? 'User',
          'last_name': account.displayName?.split(' ').skip(1).join(' ') ?? '',
          'photo_url': account.photoUrl,
        });
        ApiClient.dio.options.headers['Authorization'] = 'Bearer ${response.data['access_token']}';
        if (mounted) context.go('/home');
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
      ApiClient.dio.options.headers['Authorization'] = 'Bearer ${response.data['access_token']}';
      if (mounted) context.go('/home');
    } catch (e) {
      _showError('Admin Login Failed. Check credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 24),
              Text(
                'Welcome to MyHarur',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!_isAdminMode) ...[
                OutlinedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(child: Text("OR", style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Guest Mode
                    ApiClient.dio.options.headers.remove('Authorization');
                    context.go('/home');
                  },
                  child: const Text('Skip & Enter as Guest'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isAdminMode = true),
                  child: const Text('Admin Login', style: TextStyle(color: Colors.grey)),
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleAdminLogin,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Login as Admin'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isAdminMode = false),
                  child: const Text('Back to User Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
