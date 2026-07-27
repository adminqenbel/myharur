import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api_client.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  bool _isMaintenanceMode = false;
  
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  List<dynamic> _pendingNews = [];
  
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/config/'),
        ApiClient.dio.get('/admin/stats'),
        ApiClient.dio.get('/admin/users', queryParameters: {'q': _searchCtrl.text}),
        ApiClient.dio.get('/admin/news/pending'),
      ]);
      if (!mounted) return;
      setState(() {
        _isMaintenanceMode = results[0].data['maintenance_mode'] as bool? ?? false;
        _stats = results[1].data;
        _users = results[2].data;
        _pendingNews = results[3].data;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData();
    });
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.dio.post('/config/maintenance', data: {'maintenance_mode': value});
      setState(() => _isMaintenanceMode = value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? 'Maintenance Mode ON' : 'Maintenance Mode OFF')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportUsers() async {
    final url = '${ApiClient.dio.options.baseUrl}/admin/users/export';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open export link')));
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
            isExpanded: true,
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
                  if (mounted) Navigator.pop(ctx);
                  _fetchData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _banUserDialog(int userId, bool isCurrentlyBanned) {
    final _reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyBanned ? 'Unban User?' : 'Ban User?'),
        content: isCurrentlyBanned 
            ? const Text('This will restore the user\'s access.')
            : TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for ban', border: OutlineInputBorder()),
                maxLines: 2,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red),
            onPressed: () async {
              try {
                if (isCurrentlyBanned) {
                  await ApiClient.dio.put('/admin/users/$userId/unban');
                } else {
                  await ApiClient.dio.put('/admin/users/$userId/ban', data: {'reason': _reasonCtrl.text.trim()});
                }
                if (mounted) Navigator.pop(ctx);
                _fetchData();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isCurrentlyBanned ? 'Unban' : 'Ban', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetPassword(int userId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password?'),
        content: const Text('This will generate a temporary random password for this user. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final r = await ApiClient.dio.put('/admin/users/$userId/reset-password');
                if (mounted) {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (c2) => AlertDialog(
                      title: const Text('Password Reset'),
                      content: Text('Temporary Password:\n\n${r.data['temp_password']}\n\nPlease copy this now.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c2), child: const Text('OK'))],
                    )
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveNews(int newsId) async {
    try {
      await ApiClient.dio.put('/admin/news/$newsId/approve');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News approved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectNews(int newsId) async {
    try {
      await ApiClient.dio.put('/admin/news/$newsId/reject');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('News rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 2,
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.article), text: 'News'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
          ],
        ),
        body: _isLoading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildUsersTab(),
                  _buildNewsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
            subtitle: const Text('Block access for all non-admin users'),
            value: _isMaintenanceMode,
            onChanged: _toggleMaintenance,
            activeColor: Colors.red,
            tileColor: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 24),
          const Text('Platform Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Users', _stats['total_users']?.toString() ?? '0', Icons.people, Colors.blue),
              _buildStatCard('Active Users', _stats['active_users']?.toString() ?? '0', Icons.check_circle, Colors.green),
              _buildStatCard('Banned Users', _stats['banned_users']?.toString() ?? '0', Icons.block, Colors.red),
              _buildStatCard('Incomplete Setup', _stats['users_without_username']?.toString() ?? '0', Icons.warning, Colors.orange),
              _buildStatCard('Pending News', _stats['pending_news']?.toString() ?? '0', Icons.article_outlined, Colors.purple),
              _buildStatCard('Approved News', _stats['approved_news']?.toString() ?? '0', Icons.article, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Username, MID, Email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _exportUsers,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final u = _users[i];
                    final roleName = u['role']?['name'] ?? 'User';
                    final isBanned = u['is_banned'] == true;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isBanned ? Colors.red.shade100 : Colors.blue.shade100,
                        child: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? Colors.red : Colors.blue),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(u['email'] ?? 'No Email', style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (u['username'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                              child: Text('@${u['username']}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('MID: ${u['mid'] ?? 'None'} • Role: $roleName', style: const TextStyle(fontSize: 12)),
                          if (isBanned && u['ban_reason'] != null)
                            Text('Banned: ${u['ban_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'role') _changeRole(u['id'], roleName);
                          if (val == 'ban') _banUserDialog(u['id'], isBanned);
                          if (val == 'reset') _resetPassword(u['id']);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'role', child: Text('Change Role')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                          PopupMenuItem(value: 'ban', child: Text(isBanned ? 'Unban User' : 'Ban User', style: TextStyle(color: isBanned ? Colors.green : Colors.red))),
                        ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
            const SizedBox(height: 16),
            const Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const Text('No pending news for moderation.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingNews.length,
      itemBuilder: (ctx, i) {
        final news = _pendingNews[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news['image_url'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(news['image_url'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(news['description'] ?? '', style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(news['author_name'] ?? 'Unknown', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        Text(news['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _rejectNews(news['id']),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject & Delete', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveNews(news['id']),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
