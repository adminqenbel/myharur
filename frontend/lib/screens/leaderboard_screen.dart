import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../theme.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(_glowController);
    _fetchLeaderboard();
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await ApiClient.dio.get('/leaderboard/');
      if (mounted) {
        setState(() {
          _leaderboard = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCustomHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primary : AppTheme.bg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppTheme.accent;
  }

  Widget _buildTopThreeNode(Map<String, dynamic> user, int rank) {
    final color = _getRankColor(rank);
    final size = rank == 1 ? 100.0 : 70.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1) const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 40),
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: rank <= 3 ? _glowAnimation.value : 0),
                ],
                image: user['avatar_url'] != null 
                    ? DecorationImage(image: NetworkImage(user['avatar_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: user['avatar_url'] == null 
                  ? Center(child: Text(user['display_name']?[0] ?? 'U', style: TextStyle(color: color, fontSize: size/2, fontWeight: FontWeight.bold)))
                  : null,
            );
          }
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Text(user['display_name'] ?? 'User', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
        Text(user['rank_title'] ?? 'Citizen', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text('${user['reward_points']} pts', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopThree() {
    if (_leaderboard.isEmpty) return const SizedBox();
    
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) Expanded(child: _buildTopThreeNode(second, 2)),
          if (first != null) Expanded(child: _buildTopThreeNode(first, 1)),
          if (third != null) Expanded(child: _buildTopThreeNode(third, 3)),
        ],
      ),
    );
  }

  Widget _buildListRank(Map<String, dynamic> user, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        border: Border.all(color: AppTheme.divider.withOpacity(isDark ? 0.1 : 0.5)),
      ),
      child: Row(
        children: [
          Text('#${index + 1}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.accent.withOpacity(0.2),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null 
                ? Text(user['display_name']?[0] ?? 'U', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['display_name'] ?? 'User', style: Theme.of(context).textTheme.titleMedium),
                Text(user['rank_title'] ?? 'Citizen', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user['reward_points']}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('pts', style: Theme.of(context).textTheme.labelSmall),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _fetchLeaderboard,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildTopThree(),
                      const SizedBox(height: 16),
                      if (_leaderboard.length > 3)
                        ..._leaderboard.sublist(3).asMap().entries.map((entry) {
                          return _buildListRank(entry.value, entry.key + 3);
                        }).toList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
