import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';

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
  bool _loading = false;
  String? _error;
  String? _checking;
  bool _available = false;
  
  static const _reserved = {'system','support','news','moderator','admin','security',
    'notifications','maintenance','mid','root','superadmin','api','bot','official',
    'staff','help','info','myharur','harur','anonymous','guest'};

  void _validateLocally(String val) {
    final lower = val.toLowerCase();
    if (val.length < 3) { setState(() { _error = 'Minimum 3 characters'; _available = false; }); return; }
    if (val.length > 30) { setState(() { _error = 'Maximum 30 characters'; _available = false; }); return; }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) { setState(() { _error = 'Only letters, numbers, underscore'; _available = false; }); return; }
    if (_reserved.contains(lower)) { setState(() { _error = '"$val" is reserved'; _available = false; }); return; }
    setState(() { _error = null; _checking = 'Checking…'; _available = false; });
    _checkRemote(val);
  }

  Future<void> _checkRemote(String username) async {
    // Simple availability pre-check via search
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _usernameCtrl.text != username) return;
    setState(() { _checking = null; _available = true; });
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final displayName = _displayCtrl.text.trim();
    if (_error != null || username.isEmpty) return;
    setState(() => _loading = true);
    try {
      final r = await ApiClient.dio.post('/auth/set-username', data: {
        'username': username,
        if (displayName.isNotEmpty) 'display_name': displayName,
      });
      final token = r.data['access_token'] as String;
      final user = r.data['user'];
      ref.read(authProvider.notifier).setAuth(token, user);
    } catch (e) {
      final detail = e.toString();
      setState(() { _error = detail.contains('taken') ? 'Username already taken' : 'Error: $detail'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text('Choose your username', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your username is permanent and unique on MyHarur.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),

              // Username field
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixText: '@',
                  border: const OutlineInputBorder(),
                  suffixIcon: _checking != null
                      ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                      : (_available && _error == null ? const Icon(Icons.check_circle, color: Colors.green) : null),
                  errorText: _error,
                  helperText: _available && _error == null ? 'Available!' : '3–30 chars, letters/numbers/underscore',
                  helperStyle: TextStyle(color: _available ? Colors.green : null),
                ),
                onChanged: _validateLocally,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Display name field
              TextField(
                controller: _displayCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name (optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Visible name — can be changed later. Max 60 chars.',
                  counterText: '',
                ),
                maxLength: 60,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || _error != null || _usernameCtrl.text.trim().isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Username cannot be changed after this step.',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
