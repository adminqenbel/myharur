import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../utils/username_validation.dart';
import '../theme.dart';

/// Mandatory screen shown when user logs in without a username.
/// Cannot be dismissed — user must pick a valid username to continue.
class UsernameSetupScreen extends ConsumerStatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  ConsumerState<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends ConsumerState<UsernameSetupScreen> {
  final _usernameCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _checking;
  bool _available = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _validateLocally(String val) {
    final err = validateUsername(val);
    if (err != null) {
      setState(() { _error = err; _available = false; _checking = null; });
      return;
    }
    setState(() { _error = null; _checking = 'Checking…'; _available = false; });
    _checkRemote(val);
  }

  Future<void> _checkRemote(String username) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || _usernameCtrl.text != username) return;
    try {
      final r = await ApiClient.dio.get('/auth/check-username', queryParameters: {'username': username});
      if (!mounted || _usernameCtrl.text != username) return;
      final data = r.data as Map<String, dynamic>;
      setState(() {
        _checking = null;
        _available = data['available'] == true;
        _error = data['error'] as String?;
      });
    } catch (_) {
      if (mounted && _usernameCtrl.text == username) {
        setState(() { _checking = null; _available = false; _error = 'Could not verify username'; });
      }
    }
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final displayName = _displayCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    
    if (_error != null || username.isEmpty || !_available) return;
    
    if (phone.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Please enter a valid 10-digit Indian mobile number');
      return;
    }
    
    if (displayName.isNotEmpty) {
      final dnErr = validateDisplayName(displayName);
      if (dnErr != null) {
        setState(() => _error = dnErr);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final r = await ApiClient.dio.post('/auth/set-username', data: {
        'username': username,
        if (displayName.isNotEmpty) 'display_name': displayName,
        'phone': phone,
      });
      final token = r.data['access_token'] as String;
      final user = r.data['user'];
      await ref.read(authProvider.notifier).setAuth(token, user);
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (!auth.isSetupComplete) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      setState(() {
        _error = detail?.toString() ?? 'Could not set username';
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mid = ref.watch(authProvider).mid;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text('Choose your username', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'Your username is used for @mentions in chat and is unique on MyHarur.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
                if (mid != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Your Member ID: $mid', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 32),

                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    border: const OutlineInputBorder(),
                    suffixIcon: _checking != null
                        ? SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : (_available && _error == null ? Icon(Icons.check_circle, color: Colors.green) : null),
                    errorText: _error,
                    helperText: _available && _error == null ? 'Available!' : '3–30 chars, letters/numbers/underscore',
                    helperStyle: TextStyle(color: _available ? Colors.green : null),
                  ),
                  onChanged: _validateLocally,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),

                TextField(
                  controller: _displayCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name (optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Visible name — can be changed later. Max 60 chars.',
                    counterText: '',
                  ),
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                ),
                SizedBox(height: 16),
                
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                    helperText: '10-digit mobile number for local updates.',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading || _error != null || !_available || _usernameCtrl.text.trim().isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                    child: _loading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
                        : Text('Continue', style: TextStyle(fontSize: 16)),
                  ),
                ),

                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Username cannot be changed frequently.',
                    style: TextStyle(color: AppTheme.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
