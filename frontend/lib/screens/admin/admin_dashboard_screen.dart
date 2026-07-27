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
  List<dynamic> _pendingNews = [];
  bool _isLoading = true;
  bool _isMaintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/config/'),
        ApiClient.dio.get('/admin/users'),
        ApiClient.dio.get('/admin/news/pending'),
      ]);
      setState(() {
        _isMaintenanceMode = results[0].data['maintenance_mode'] as bool? ?? false;
        _users = results[1].data;
        _pendingNews = results[2].data;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/config/maintenance', data: {'maintenance_mode': value});
      setState(() => _isMaintenanceMode = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Maintenance Mode Enabled' : 'Maintenance Mode Disabled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
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
                  _fetchData();
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

  Future<void> _approveNews(int newsId) async {
    try {
      await ApiClient.dio.post('/admin/news/$newsId/approve');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News approved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectNews(int newsId) async {
    try {
      await ApiClient.dio.post('/admin/news/$newsId/reject');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.article), text: 'Pending News'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUsersTab(),
                  _buildNewsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          subtitle: const Text('Block access for all non-admin users'),
          value: _isMaintenanceMode,
          onChanged: _toggleMaintenance,
          activeColor: Colors.red,
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
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
        ),
      ],
    );
  }

  Widget _buildNewsTab() {
    if (_pendingNews.isEmpty) {
      return const Center(child: Text('No pending news for moderation.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingNews.length,
      itemBuilder: (ctx, i) {
        final news = _pendingNews[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (news['image_url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Image.network(news['image_url'], height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                Text(news['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(news['content'] ?? ''),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _rejectNews(news['id']),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveNews(news['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
