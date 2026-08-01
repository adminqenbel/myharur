import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api_client.dart';
import '../providers/auth_provider.dart';

import '../utils/username_validation.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final profile = auth.user?['profile'] as Map<String, dynamic>? ?? {};
    _firstNameCtrl.text = profile['first_name'] ?? '';
    _lastNameCtrl.text = profile['last_name'] ?? '';
    _phoneCtrl.text = profile['phone'] ?? '';
    _addressCtrl.text = profile['address'] ?? '';
  }

  Future<void> _save() async {
    final fnErr = validateNameField(_firstNameCtrl.text, 'First name');
    final lnErr = validateNameField(_lastNameCtrl.text, 'Last name');
    if (fnErr != null || lnErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fnErr ?? lnErr!)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.put('/users/me/profile', data: {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
                SizedBox(height: 16),
                TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
                SizedBox(height: 16),
                TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                SizedBox(height: 16),
                TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                SizedBox(height: 24),
                ElevatedButton(onPressed: _save, child: Text('Save Changes')),
              ],
            ),
    );
  }
}
