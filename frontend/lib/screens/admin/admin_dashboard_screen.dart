import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api_client.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';
import '../../theme.dart';

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
  List<dynamic> _pendingShops = [];
  List<dynamic> _roles = [];
  
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
        ApiClient.dio.get('/admin/shops', queryParameters: {'status': 'pending'}).catchError((_) => null),
        ApiClient.dio.get('/admin/roles').catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _isMaintenanceMode = results[0].data['maintenance_mode'] as bool? ?? false;
        _stats = results[1].data;
        _users = results[2].data;
        _pendingNews = results[3].data;
        if (results[4] != null) _pendingShops = results[4].data ?? [];
        if (results[5] != null) _roles = results[5].data ?? [];
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

  void _showVersionManagerDialog() async {
    final versionCtrl = TextEditingController(text: '1.2.0');
    final minVersionCtrl = TextEditingController(text: '1.0.0');
    final buildNumCtrl = TextEditingController(text: '12');
    final apkUrlCtrl = TextEditingController(text: 'https://myharur.onrender.com/static/myharur.apk');
    final releaseNotesCtrl = TextEditingController(text: 'Emergency Google Maps deep-links, dynamic news ingestion, and community chat stability fixes.');
    bool forceUpdate = false;

    try {
      final res = await ApiClient.dio.get('/config/');
      versionCtrl.text = (res.data['latest_version'] ?? '1.2.0').toString();
      minVersionCtrl.text = (res.data['min_version'] ?? '1.0.0').toString();
      buildNumCtrl.text = (res.data['build_number'] ?? '12').toString();
      apkUrlCtrl.text = (res.data['apk_url'] ?? 'https://myharur.onrender.com/static/myharur.apk').toString();
      releaseNotesCtrl.text = (res.data['release_notes'] ?? '').toString();
      forceUpdate = res.data['force_update'] as bool? ?? false;
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.system_update_rounded, color: AppTheme.appleBlue),
              SizedBox(width: 8),
              Text('Version & Release Manager'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: versionCtrl,
                  decoration: const InputDecoration(labelText: 'Latest Version (e.g. 1.2.0)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minVersionCtrl,
                  decoration: const InputDecoration(labelText: 'Minimum Required Version', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: buildNumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Build Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apkUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Direct APK Download URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: releaseNotesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Release Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Force Update for All Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Prevent using app until updated'),
                  value: forceUpdate,
                  onChanged: (val) => setDialogState(() => forceUpdate = val),
                  activeColor: AppTheme.danger,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.dio.post('/config/version', data: {
                    'latest_version': versionCtrl.text.trim(),
                    'min_version': minVersionCtrl.text.trim(),
                    'build_number': int.tryParse(buildNumCtrl.text.trim()) ?? 12,
                    'apk_url': apkUrlCtrl.text.trim(),
                    'release_notes': releaseNotesCtrl.text.trim(),
                    'force_update': forceUpdate,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App Version Settings Updated Successfully!')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Publish Release'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUsers() async {
    final url = '${ApiClient.dio.options.baseUrl}/admin/users/export';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open export link')));
    }
  }

  void _changeRole(int userId, String currentRole) {
    final roles = [
      'User', 'Citizen', 'Moderator', 'Admin', 'Super Admin',
      'Government', 'Government Official', 'Police', 'Hospital', 'Municipality',
      'Shop Admin', 'Verified Business',
      'Event Head', 'Organizing Secretary', 'Volunteer',
    ];
    String selectedRole = roles.contains(currentRole) ? currentRole : 'User';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: userId == 0
              ? const Text('Role Information')
              : const Text('Change Role'),
          content: DropdownButton<String>(
            isExpanded: true,
            value: roles.contains(selectedRole) ? selectedRole : 'User',
            items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setDialogState(() => selectedRole = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
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
              child: Text('Save'),
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
            ? Text('This will restore the user\'s access.')
            : TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for ban', border: OutlineInputBorder()),
                maxLines: 2,
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyBanned ? Colors.green : AppTheme.danger),
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
            child: Text(isCurrentlyBanned ? 'Unban' : 'Ban', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
          ),
        ],
      ),
    );
  }

  void _resetPassword(int userId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password?'),
        content: Text('This will generate a temporary random password for this user. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final r = await ApiClient.dio.put('/admin/users/$userId/reset-password');
                if (mounted) {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (c2) => AlertDialog(
                      title: Text('Password Reset'),
                      content: Text('Temporary Password:\n\n${r.data['temp_password']}\n\nPlease copy this now.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(c2), child: Text('OK'))],
                    )
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveNews(int newsId) async {
    try {
      await ApiClient.dio.put('/admin/news/$newsId/approve');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News approved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectNews(int newsId) async {
    try {
      await ApiClient.dio.put('/admin/news/$newsId/reject');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingShopCount = _pendingShops.length;
    final pendingNewsCount = _pendingNews.length;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppTheme.accent,
            indicatorWeight: 3,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textSecondaryLight,
            isScrollable: true,
            tabs: [
              const Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
              const Tab(icon: Icon(Icons.people_rounded), text: 'Users'),
              Tab(
                icon: Badge(
                  label: Text('$pendingNewsCount'),
                  isLabelVisible: pendingNewsCount > 0,
                  child: const Icon(Icons.article_rounded),
                ),
                text: 'News',
              ),
              Tab(
                icon: Badge(
                  label: Text('$pendingShopCount'),
                  isLabelVisible: pendingShopCount > 0,
                  child: const Icon(Icons.store_rounded),
                ),
                text: 'Shops',
              ),
              const Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Roles'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData),
          ],
        ),
        body: _isLoading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildUsersTab(),
                  _buildNewsTab(),
                  _buildShopsTab(),
                  _buildRolesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 18)),
            subtitle: Text('Block access for all non-admin users'),
            value: _isMaintenanceMode,
            onChanged: _toggleMaintenance,
            activeColor: AppTheme.danger,
            tileColor: AppTheme.danger.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          SizedBox(height: 16),
          ListTile(
            tileColor: AppTheme.appleBlue.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.appleBlue.withOpacity(0.2))),
            leading: Icon(Icons.system_update_rounded, color: AppTheme.appleBlue, size: 28),
            title: Text('App Release & Version Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.appleBlue)),
            subtitle: Text('Manage version numbers, release notes & force updates'),
            trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.appleBlue),
            onTap: _showVersionManagerDialog,
          ),
          SizedBox(height: 24),
          Text('Platform Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Users', _stats['total_users']?.toString() ?? '0', Icons.people_rounded, Colors.blue),
              _buildStatCard('Active Users', _stats['active_users']?.toString() ?? '0', Icons.check_circle_rounded, Colors.green),
              _buildStatCard('Banned Users', _stats['banned_users']?.toString() ?? '0', Icons.block_rounded, AppTheme.danger),
              _buildStatCard('Pending News', _stats['pending_news']?.toString() ?? '0', Icons.article_outlined, Colors.purple),
              _buildStatCard('Approved Shops', _stats['approved_shops']?.toString() ?? '0', Icons.store_rounded, Colors.green),
              _buildStatCard('Pending Shops', _stats['pending_shops']?.toString() ?? '0', Icons.hourglass_empty_rounded, Colors.orange),
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
              ],
            ),
            SizedBox(height: 12),
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
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search Username, MID, Email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _exportUsers,
                icon: Icon(Icons.download, size: 18),
                label: Text('Export'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading && _users.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final u = _users[i];
                    final roleName = u['role']?['name'] ?? 'User';
                    final isBanned = u['is_banned'] == true;
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isBanned ? AppTheme.danger : Colors.blue,
                        child: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? AppTheme.danger : Colors.blue),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(u['email'] ?? 'No Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          if (u['username'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                              child: Text('@${u['username']}', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            '${u['display_name'] ?? u['email'] ?? 'No Name'} • MID: ${u['mid'] ?? 'None'} • Role: $roleName',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (isBanned && u['ban_reason'] != null)
                            Text('Banned: ${u['ban_reason']}', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
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
                          PopupMenuItem(value: 'ban', child: Text(isBanned ? 'Unban User' : 'Ban User', style: TextStyle(color: isBanned ? Colors.green : AppTheme.danger))),
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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All caught up!', style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            Text('No pending news for moderation.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _pendingNews.length,
      itemBuilder: (ctx, i) {
        final news = _pendingNews[i];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news['image_url'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(news['image_url'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => SizedBox()),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(news['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 8),
                    Text(news['description'] ?? '', style: TextStyle(color: Colors.black87)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(width: 4),
                        Text(news['author_name'] ?? 'Unknown', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                        Spacer(),
                        Text(news['created_at']?.toString().substring(0, 10) ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _rejectNews(news['id']),
                          icon: Icon(Icons.close, color: AppTheme.danger),
                          label: Text('Reject & Delete', style: TextStyle(color: AppTheme.danger)),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveNews(news['id']),
                          icon: Icon(Icons.check, color: Theme.of(context).colorScheme.surface),
                          label: Text('Approve', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
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

  // ── Shops Approval Tab ────────────────────────────────────────────────────

  Future<void> _approveShop(int shopId) async {
    try {
      await ApiClient.dio.put('/admin/shops/$shopId/approve');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Shop approved and live!'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectShop(int shopId) async {
    try {
      await ApiClient.dio.put('/admin/shops/$shopId/reject');
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop rejected'), backgroundColor: AppTheme.danger),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildShopsTab() {
    return _pendingShops.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 56, color: AppTheme.success),
                ),
                const SizedBox(height: 16),
                const Text('All Caught Up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('No shops pending approval.', style: TextStyle(color: AppTheme.textSecondaryLight)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingShops.length,
            itemBuilder: (ctx, i) {
              final shop = _pendingShops[i] as Map<String, dynamic>;
              final cat = shop['category'] as Map<String, dynamic>?;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Text(cat?['icon'] ?? '🏪', style: const TextStyle(fontSize: 28)),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(shop['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cat != null) Text(cat['name'], style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                          if (shop['address'] != null) Text(shop['address'], style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 12)),
                          if (shop['owner_name'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_rounded, size: 13, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('${shop['owner_name']} · ${shop['owner_phone'] ?? ''} · ${shop['owner_email'] ?? ''}',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _rejectShop(shop['id'] as int),
                            icon: const Icon(Icons.close_rounded, color: AppTheme.danger, size: 18),
                            label: const Text('Reject', style: TextStyle(color: AppTheme.danger)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _approveShop(shop['id'] as int),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve'),
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

  // ── Roles Management Tab ──────────────────────────────────────────────────

  Widget _buildRolesTab() {
    final allRoles = [
      'Super Admin', 'Admin', 'Moderator', 'User', 'Citizen',
      'Government', 'Government Official', 'Police', 'Hospital', 'Municipality',
      'Shop Admin', 'Verified Business',
      'Event Head', 'Organizing Secretary', 'Volunteer',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Roles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Manage platform roles and permissions', style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13)),
          const SizedBox(height: 16),
          ..._roles.isEmpty
              ? allRoles.map((name) => _roleCard(name, null, 0))
              : _roles.map((r) => _roleCard(r['name'] as String, r['id'] as int?, r['user_count'] as int? ?? 0)),
        ],
      ),
    );
  }

  Widget _roleCard(String name, int? id, int userCount) {
    Color roleColor;
    IconData roleIcon;
    switch (name) {
      case 'Super Admin': roleColor = const Color(0xFFFF6B6B); roleIcon = Icons.shield_rounded; break;
      case 'Admin': roleColor = AppTheme.accent; roleIcon = Icons.admin_panel_settings_rounded; break;
      case 'Moderator': roleColor = Colors.purple; roleIcon = Icons.manage_accounts_rounded; break;
      case 'Government':
      case 'Government Official': roleColor = Colors.teal; roleIcon = Icons.account_balance_rounded; break;
      case 'Police': roleColor = Colors.indigo; roleIcon = Icons.local_police_rounded; break;
      case 'Hospital': roleColor = Colors.red; roleIcon = Icons.local_hospital_rounded; break;
      case 'Municipality': roleColor = Colors.brown; roleIcon = Icons.location_city_rounded; break;
      case 'Shop Admin': roleColor = Colors.orange; roleIcon = Icons.store_rounded; break;
      case 'Verified Business': roleColor = Colors.green; roleIcon = Icons.verified_rounded; break;
      case 'Event Head': roleColor = Colors.pink; roleIcon = Icons.event_rounded; break;
      default: roleColor = Colors.grey; roleIcon = Icons.person_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: roleColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: roleColor)),
                Text('$userCount users', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _changeRole(0, name),
            style: TextButton.styleFrom(foregroundColor: roleColor),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
