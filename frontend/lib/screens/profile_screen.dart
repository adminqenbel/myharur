import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user ?? {};
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    final role = user['role'] as Map<String, dynamic>? ?? {};

    final firstName = profile['first_name'] ?? '';
    final lastName = profile['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = user['email'] ?? 'No Email';
    final phone = profile['phone'] ?? 'Not set';
    final address = profile['address'] ?? 'Not set';
    final avatarUrl = profile['avatar_url'] as String?;
    final streak = profile['streak_days'] ?? 0;
    final rewards = profile['reward_points'] ?? 0;
    final roleName = role['name'] ?? 'User';
    final mid = user['mid'] ?? '—';
    final username = user['username'] as String?;
    final displayName = user['display_name'] as String?;
    final isSetup = user['is_setup_complete'] == true;
    final provider = user['login_provider'] ?? 'email';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.blue.shade900,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade900, Colors.indigo.shade600],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      backgroundColor: Colors.white,
                      child: avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.blue) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isEmpty
                          ? (displayName ?? (username != null ? '@$username' : (isSetup ? email : 'Complete Your Profile')))
                          : fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('@$username', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleName == 'Super Admin' ? Colors.amber : roleName == 'Admin' ? Colors.orange : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(roleName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => context.push('/settings')),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Stats Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('${streak}', 'Day Streak', Icons.local_fire_department, Colors.orange),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _stat('${rewards}', 'Reward Pts', Icons.star, Colors.amber),
                      Container(width: 1, height: 40, color: Colors.grey.shade200),
                      _stat(roleName, 'Role', Icons.shield, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Profile Details
                _section('Personal Info', [
                  _tile(Icons.email_outlined, 'Email', email),
                  _tile(Icons.phone_outlined, 'Phone', phone),
                  _tile(Icons.home_outlined, 'Address', address),
                  _tile(Icons.badge_outlined, 'Member ID (MID)', mid),
                ]),
                const SizedBox(height: 12),

                // Account Actions
                _section('Account', [
                  _actionTile(Icons.edit, 'Edit Profile', Colors.blue, () => context.push('/edit-profile')),
                  if (provider != 'google')
                    _actionTile(Icons.lock_outline, 'Change Password', Colors.orange, () => context.push('/change-password')),
                  if (provider == 'google')
                    _actionTile(Icons.lock_open, 'Set Password', Colors.purple, () => context.push('/set-password')),
                  if (auth.isAdmin)
                    _actionTile(Icons.admin_panel_settings, 'Admin Dashboard', Colors.red, () => context.push('/admin')),
                ]),
                const SizedBox(height: 12),

                _section('Preferences', [
                  _actionTile(Icons.translate, 'Language Settings', Colors.teal, () => context.push('/settings')),
                  _actionTile(Icons.notifications_outlined, 'Notifications', Colors.indigo, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications coming soon!')));
                  }),
                  _actionTile(Icons.help_outline, 'Help & Support', Colors.green, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support coming soon!')));
                  }),
                ]),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (mounted) context.go('/login');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 0.5)),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
