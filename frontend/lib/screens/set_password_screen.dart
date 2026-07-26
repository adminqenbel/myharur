import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _newCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_newCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/auth/set-password', data: {
        'new_password': _newCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password set successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to set password.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Since you logged in with Google, you can set a password to also log in with your email.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(controller: _newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text('Set Password')),
        ],
      ),
    );
  }
}
