import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../theme.dart';
import '../widgets/design_system.dart';

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
    final roles = auth.roles;
    final roleName = roles.isNotEmpty ? roles.join(', ') : 'Citizen';
    final mid = user['mid'] ?? '—';
    final username = user['username'] as String?;
    final displayName = user['display_name'] as String?;
    final isSetup = user['is_setup_complete'] == true;
    final provider = user['login_provider'] ?? 'email';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    MHAvatar(url: avatarUrl, radius: 45, fallback: fullName.isNotEmpty ? fullName[0] : null),
                    const SizedBox(height: 12),
                    Text(
                      fullName.isEmpty
                          ? (displayName ?? (username != null ? '@$username' : (isSetup ? email : 'Complete Your Profile')))
                          : fullName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    if (username != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('@$username', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    const SizedBox(height: 8),
                    MHBadge(text: roleName, color: auth.isSuperAdmin ? AppTheme.accent : AppTheme.info),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () => context.push('/settings')),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Stats Row
                  MHCard(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _stat('${streak}', 'Day Streak', Icons.local_fire_department, AppTheme.accent),
                        Container(width: 1, height: 40, color: AppTheme.divider),
                        _stat('${rewards}', 'Reputation', Icons.workspace_premium, AppTheme.accent),
                        Container(width: 1, height: 40, color: AppTheme.divider),
                        _stat(roleName, 'Role', Icons.shield, AppTheme.info),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Details
                  _section('Personal Info', [
                    _tile(Icons.email_outlined, 'Email', email),
                    _tile(Icons.phone_outlined, 'Phone', phone),
                    _tile(Icons.home_outlined, 'Address', address),
                    _tile(Icons.badge_outlined, 'Member ID (MID)', mid),
                  ]),
                  const SizedBox(height: 16),

                  // Account Actions
                  _section('Account', [
                    _actionTile(Icons.edit, 'Edit Profile', AppTheme.info, () => context.push('/edit-profile')),
                    if (provider != 'google')
                      _actionTile(Icons.lock_outline, 'Change Password', AppTheme.accent, () => context.push('/change-password')),
                    if (provider == 'google')
                      _actionTile(Icons.lock_open, 'Set Password', Colors.purple, () => context.push('/set-password')),
                    if (auth.isAdmin)
                      _actionTile(Icons.admin_panel_settings, 'Admin Dashboard', AppTheme.danger, () => context.push('/admin')),
                  ]),
                  const SizedBox(height: 16),

                  _section('Preferences', [
                    _actionTile(Icons.translate, 'Language Settings', AppTheme.success, () => context.push('/settings')),
                    _actionTile(Icons.notifications_outlined, 'Notifications', AppTheme.info, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications coming soon!')));
                    }),
                    _actionTile(Icons.help_outline, 'Help & Support', AppTheme.success, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support coming soon!')));
                    }),
                  ]),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: AppTheme.danger),
                      label: const Text('Logout', style: TextStyle(color: AppTheme.danger, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (mounted) context.go('/login');
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // padding for nav bar
                ],
              ),
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
    return MHCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryLight, letterSpacing: 0.5)),
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
