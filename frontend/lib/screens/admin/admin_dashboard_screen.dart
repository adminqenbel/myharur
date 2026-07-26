import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api_client.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final r = await ApiClient.dio.get('/admin/users');
      setState(() => _users = r.data);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeRole(int userId, String currentRole) {
    final roles = ['User', 'Moderator', 'Admin', 'Super Admin'];
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Role'),
          content: DropdownButton<String>(
            value: roles.contains(selectedRole) ? selectedRole : 'User',
            items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setDialogState(() => selectedRole = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.dio.put('/admin/users/$userId/role', data: {'role_name': selectedRole});
                  Navigator.pop(ctx);
                  _fetchUsers();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                final roleName = u['role']?['name'] ?? 'User';
                return ListTile(
                  title: Text(u['email'] ?? ''),
                  subtitle: Text('Role: $roleName | Setup: ${u['is_setup_complete'] ?? false}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _changeRole(u['id'], roleName),
                  ),
                );
              },
            ),
    );
  }
}
