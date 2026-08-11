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
  
  String _category = 'community';
  String _timeframe = 'all_time';

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
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.get('/leaderboard/', queryParameters: {
        'category': _category,
        'timeframe': _timeframe
      });
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
      padding: EdgeInsets.only(top: 40, left: 16, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
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
  
  Color _getTierColor(String? tier) {
    switch(tier) {
      case 'Legend': return const Color(0xFFFF00FF);
      case 'Elite': return const Color(0xFF000000);
      case 'Emerald': return const Color(0xFF50C878);
      case 'Ruby': return const Color(0xFFE0115F);
      case 'Diamond': return const Color(0xFFB9F2FF);
      case 'Platinum': return const Color(0xFFE5E4E2);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Silver': return const Color(0xFFC0C0C0);
      default: return const Color(0xFFCD7F32); // Bronze
    }
  }
  
  Color _getVerificationColor(String? level) {
    switch(level) {
      case 'Government':
      case 'Police':
        return AppTheme.danger;
      case 'Business':
      case 'Hospital':
        return Colors.green;
      case 'Verified Citizen':
      case 'Volunteer':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }

  Widget _buildTopThreeNode(Map<String, dynamic> user, int rank) {
    final color = _getRankColor(rank);
    final size = rank == 1 ? 100.0 : 70.0;
    
    final tierColor = _getTierColor(user['tier_badge']);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1) Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 40),
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tierColor, width: 3),
                boxShadow: [
                  BoxShadow(color: tierColor.withOpacity(0.5), blurRadius: rank <= 3 ? _glowAnimation.value : 0),
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
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5))
          ),
          child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(user['display_name'] ?? 'User', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
            if (user['verification_level'] != 'Citizen') ...[
              SizedBox(width: 4),
              Icon(Icons.verified, size: 14, color: _getVerificationColor(user['verification_level'])),
            ]
          ],
        ),
        Text('${user['tier_badge'] ?? 'Bronze'} Tier', style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('${user['reputation_score']?.toStringAsFixed(0) ?? 0} pts', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopThree() {
    if (_leaderboard.isEmpty) return SizedBox();
    
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
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
    final tierColor = _getTierColor(user['tier_badge']);
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        border: Border.all(color: tierColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#${index + 1}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tierColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: tierColor.withOpacity(0.2),
              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
              child: user['avatar_url'] == null 
                  ? Text(user['display_name']?[0] ?? 'U', style: TextStyle(color: tierColor, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(user['display_name'] ?? 'User', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                    if (user['verification_level'] != 'Citizen') ...[
                      SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: _getVerificationColor(user['verification_level'])),
                    ]
                  ],
                ),
                Text('${user['tier_badge'] ?? 'Bronze'} Tier', style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user['reputation_score']?.toStringAsFixed(0) ?? 0}', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 18)),
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
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Community', 'community', _category, (val) => setState((){ _category = val; _fetchLeaderboard(); })),
                SizedBox(width: 8),
                _buildFilterChip('Emergency', 'emergency', _category, (val) => setState((){ _category = val; _fetchLeaderboard(); })),
                SizedBox(width: 8),
                _buildFilterChip('Volunteer', 'volunteer', _category, (val) => setState((){ _category = val; _fetchLeaderboard(); })),
                SizedBox(width: 8),
                _buildFilterChip('Business', 'business', _category, (val) => setState((){ _category = val; _fetchLeaderboard(); })),
                SizedBox(width: 8),
                _buildFilterChip('Government', 'government', _category, (val) => setState((){ _category = val; _fetchLeaderboard(); })),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _fetchLeaderboard,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildTopThree(),
                      SizedBox(height: 16),
                      if (_leaderboard.length > 3)
                        ..._leaderboard.sublist(3).asMap().entries.map((entry) {
                          return _buildListRank(entry.value, entry.key + 3);
                        }).toList(),
                      SizedBox(height: 160),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) => onSelected(value),
      selectedColor: AppTheme.accent.withOpacity(0.2),
      labelStyle: TextStyle(color: isSelected ? AppTheme.accent : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
    );
  }
}
