import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_components.dart';
import 'chat_page.dart';
import 'events_page.dart';

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Polls state
  final List<Map<String, dynamic>> _polls = [
    {
      'id': 1,
      'question': 'Should Harur Municipality prioritize broad gauge passenger train trial runs to Morappur this quarter?',
      'category': 'Infrastructure',
      'totalVotes': 428,
      'userVotedIndex': null,
      'options': [
        {'text': 'Yes, immediately launch passenger trials', 'votes': 382},
        {'text': 'No, finish station amenities first', 'votes': 36},
        {'text': 'Neutral / Need more study', 'votes': 10},
      ],
    },
    {
      'id': 2,
      'question': 'Which Harur road requires immediate pothole resurfacing and streetlight upgrade?',
      'category': 'Civic Works',
      'totalVotes': 296,
      'userVotedIndex': null,
      'options': [
        {'text': 'Bazaar Street to Old Bus Stand', 'votes': 142},
        {'text': 'Morappur Main Road Corridor', 'votes': 98},
        {'text': 'Theerthamalai Temple Access Road', 'votes': 56},
      ],
    },
  ];

  // Town Hall Q&A
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 1,
      'author': 'Selvam (Ward 4)',
      'question': 'When will the Harur combined drinking water supply pipe expansion reach South Kottapatti?',
      'answer': 'Municipal Engineer Office: Pipeline laying is 85% completed. House connections will commence next month.',
      'upvotes': 48,
      'answered': true,
      'time': '2h ago',
    },
    {
      'id': 2,
      'author': 'Priya M. (Merchant)',
      'question': 'Are there special trade subsidies for sugarcane jaggery producers at Harur Regulated Market this season?',
      'answer': 'Krishi Vigyan Kendra: Yes, 20% freight concession is applicable for registered cooperative members.',
      'upvotes': 34,
      'answered': true,
      'time': '5h ago',
    },
  ];

  // Topic Chat Channels
  final List<Map<String, dynamic>> _channels = [
    {
      'name': '#harur-general',
      'topic': 'Daily town pulse, announcements, and neighbor discussions.',
      'members': '1.2k Residents',
      'activeNow': '42 Online',
      'icon': Icons.forum_rounded,
      'color': const Color(0xFF007AFF),
    },
    {
      'name': '#agriculture-mandi',
      'topic': 'Crop prices, harvest rates, tractor rentals & fertilizer advice.',
      'members': '850 Farmers',
      'activeNow': '18 Online',
      'icon': Icons.agriculture_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': '#jobs-and-hiring',
      'topic': 'Daily wages, drivers, shop staff, and regional vacancies.',
      'members': '640 Workers',
      'activeNow': '12 Online',
      'icon': Icons.work_rounded,
      'color': const Color(0xFF267AF4),
    },
    {
      'name': '#youth-and-education',
      'topic': 'College admissions, TNPSC coaching, sports & tournaments.',
      'members': '510 Students',
      'activeNow': '15 Online',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _vote(int pollIndex, int optionIndex) {
    setState(() {
      final poll = _polls[pollIndex];
      if (poll['userVotedIndex'] == null) {
        poll['userVotedIndex'] = optionIndex;
        poll['totalVotes'] = (poll['totalVotes'] as int) + 1;
        final opts = poll['options'] as List;
        opts[optionIndex]['votes'] = (opts[optionIndex]['votes'] as int) + 1;
      }
    });
  }

  void _openAskQuestionSheet() {
    final qCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask in Town Hall Q&A',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
            ),
            const SizedBox(height: 4),
            const Text('Questions are directed to Harur municipal heads and community leaders.', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
            const SizedBox(height: 16),
            TextField(
              controller: qCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Your civic question or topic...',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final text = qCtrl.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _questions.insert(0, {
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'author': AuthService.currentProfile.fullName,
                        'question': text,
                        'answer': 'Pending response from Harur authorities.',
                        'upvotes': 1,
                        'answered': false,
                        'time': 'Just now',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: Color(0xFF007AFF), content: Text('✓ Question posted to Town Hall!')),
                    );
                  }
                },
                child: const Text('Post Question', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Community Hub',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF007AFF),
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: const Color(0xFF007AFF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Polls'),
            Tab(text: 'Town Hall'),
            Tab(text: 'Channels'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPollsTab(),
          _buildTownHallTab(),
          _buildChannelsTab(),
          const EventsPage(),
        ],
      ),
    );
  }

  Widget _buildPollsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _polls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, pollIdx) {
        final poll = _polls[pollIdx];
        final totalVotes = poll['totalVotes'] as int;
        final userVoted = poll['userVotedIndex'] != null;

        return GlassCard(
          level: GlassLevel.level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      poll['category'].toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF007AFF)),
                    ),
                  ),
                  const Spacer(),
                  Text('$totalVotes Votes', style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                poll['question'] as String,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1C1C1E), height: 1.3),
              ),
              const SizedBox(height: 16),

              // Options
              ...List.generate((poll['options'] as List).length, (optIdx) {
                final opt = (poll['options'] as List)[optIdx];
                final votes = opt['votes'] as int;
                final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
                final isSelected = poll['userVotedIndex'] == optIdx;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _vote(pollIdx, optIdx),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEBF5FF) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? const Color(0xFF007AFF) : Colors.transparent, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  opt['text'] as String,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    fontSize: 13,
                                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                              if (userVoted) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${(pct * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (userVoted) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE5E5EA),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSelected ? const Color(0xFF007AFF) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTownHallTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.help_outline_rounded),
        label: const Text('Ask Question', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openAskQuestionSheet,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final q = _questions[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(q['author'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF8E8E93))),
                    const Spacer(),
                    Text(q['time'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q['question'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Color(0xFF007AFF), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q['answer'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => q['upvotes'] = (q['upvotes'] as int) + 1),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF007AFF)),
                          const SizedBox(width: 4),
                          Text('${q['upvotes']} Helpful', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF007AFF))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (q['answered'] == true)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF), size: 14),
                          SizedBox(width: 4),
                          Text('Official Response', style: TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelsTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final ch = _channels[i];
        final color = ch['color'] as Color;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TownChatPage())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(ch['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text(ch['topic'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(ch['members'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 8),
                          const Icon(Icons.circle, size: 6, color: Color(0xFF007AFF)),
                          const SizedBox(width: 4),
                          Text(ch['activeNow'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF007AFF))),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        );
      },
    );
  }
}
