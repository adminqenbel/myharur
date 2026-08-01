import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../services/socket_service.dart';
import 'chat_room_screen.dart';
import '../widgets/design_system.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _polls = [];
  List<dynamic> _events = [];
  List<dynamic> _questions = [];
  List<dynamic> _chatRooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      ApiClient.dio.get('/community/polls').then((response) => response.data).catchError((_) => _polls),
      ApiClient.dio.get('/community/events').then((response) => response.data).catchError((_) => _events),
      ApiClient.dio.get('/community/questions').then((response) => response.data).catchError((_) => _questions),
      ApiClient.dio.get('/community/chat/rooms').then((response) => response.data).catchError((_) => _chatRooms),
    ]);
    if (!mounted) return;
    setState(() {
      _polls = results[0] as List<dynamic>;
      _events = results[1] as List<dynamic>;
      _questions = results[2] as List<dynamic>;
      _chatRooms = results[3] as List<dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l(ref, 'Community Hub'), style: theme.textTheme.headlineMedium),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.accent,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              indicator: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorPadding: EdgeInsets.symmetric(horizontal: -12, vertical: 8),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(icon: Icon(Icons.how_to_vote_rounded, size: 20), text: 'Polls'),
                Tab(icon: Icon(Icons.event_rounded, size: 20), text: 'Events'),
                Tab(icon: Icon(Icons.forum_rounded, size: 20), text: 'Q&A'),
                Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), text: 'Chat'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPolls(),
                _buildEvents(),
                _buildQA(),
                _buildChatRooms(),
              ],
            ),
    );
  }

  Widget? _buildFAB() {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return null;

    final role = auth.user?['role']?['name'] ?? '';
    final canCreateRoom = ['Super Admin', 'Admin', 'Moderator', 'Government', 'Police', 'Municipality'].contains(role);

    // If on Chat tab and not authorized, hide FAB
    if (_tabController.index == 3 && !canCreateRoom) return null;

    return Padding(
      padding: EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        onPressed: () {
          switch (_tabController.index) {
            case 0: _showCreatePollDialog(); break;
            case 1: _showCreateEventDialog(); break;
            case 2: _showCreateQuestionDialog(); break;
            case 3: _showCreateChatRoomDialog(); break;
          }
        },
        child: Icon(Icons.add_rounded, color: AppTheme.textPrimaryLight, size: 28),
      ),
    );
  }

  // ── Polls ──────────────────────────────────────────────────────────────────
  Widget _buildPolls() {
    if (_polls.isEmpty) return const MHEmptyState(icon: Icons.how_to_vote_rounded, title: 'No Polls Yet', description: 'Check back later or start a new poll.');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _polls.length,
        itemBuilder: (ctx, i) => _buildPollCard(_polls[i]),
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll) {
    final options = (poll['options'] as List? ?? []);
    final totalVotes = options.fold<int>(0, (sum, o) => sum + (o['vote_count'] as int? ?? 0));
    final votedId = poll['user_voted_option_id'] as int?;

    List<Widget> optionWidgets = [];
    for (var opt in options) {
      final votes = opt['vote_count'] as int? ?? 0;
      final pct = totalVotes > 0 ? votes / totalVotes : 0.0;
      final isVoted = votedId == opt['id'];
      optionWidgets.add(
        InkWell(
          onTap: votedId != null ? null : () => _castVote(poll['id'], opt['id']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(opt['text'] ?? '', style: TextStyle(fontWeight: isVoted ? FontWeight.w800 : FontWeight.w600, color: isVoted ? const Color(0xFF007AFF) : Theme.of(context).colorScheme.onSurface)),
                  Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    color: isVoted ? const Color(0xFF007AFF) : AppTheme.info.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        )
      );
    }

    return MHCard(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll['question'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...optionWidgets,
          SizedBox(height: 8),
          Text('$totalVotes votes', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _castVote(int pollId, int optionId) async {
    try {
      await ApiClient.dio.post('/community/polls/$pollId/vote', data: {'option_id': optionId});
      _fetchAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final option1 = TextEditingController();
    final option2 = TextEditingController();
    final option3 = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Create a Poll', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 20),
            TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Poll Question *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: option1, decoration: const InputDecoration(labelText: 'Option 1 *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: option2, decoration: const InputDecoration(labelText: 'Option 2 *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: option3, decoration: const InputDecoration(labelText: 'Option 3 (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSubmitting ? null : () async {
                  final options = [option1.text, option2.text, option3.text]
                      .map((option) => option.trim())
                      .where((option) => option.isNotEmpty)
                      .toList();
                  if (questionCtrl.text.isEmpty || options.length < 2) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/polls', data: {'question': questionCtrl.text, 'options': options});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Create Poll', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ),
          ]),
        ),
      ),
    );
  }

  // ── Events ─────────────────────────────────────────────────────────────────
  Widget _buildEvents() {
    if (_events.isEmpty) return const MHEmptyState(icon: Icons.event_rounded, title: 'No Events Yet', description: 'Be the first to create an event!');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _events.length,
        itemBuilder: (ctx, i) {
          final event = _events[i];
          return MHCard(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['image_url'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(imageUrl: event['image_url'], width: double.infinity, height: 160, fit: BoxFit.cover, errorWidget: (_, __, ___) => SizedBox()),
                  ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(event['title'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    if (event['event_date'] != null)
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.info),
                        SizedBox(width: 8),
                        Text(event['event_date'].toString().substring(0, 10), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    SizedBox(height: 8),
                    if (event['location_name'] != null)
                      Row(children: [
                        Icon(Icons.location_on_rounded, size: 16, color: AppTheme.danger),
                        SizedBox(width: 8),
                        Text(event['location_name'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    if (event['description'] != null) ...[SizedBox(height: 16), Text(event['description'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5))],
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Create Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 20),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 2),
            SizedBox(height: 12),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Payment / Registration Link (Google Forms)', hintText: 'Optional external link', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSubmitting ? null : () async {
                  if (titleCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/events', data: {
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'location_name': locationCtrl.text,
                      'event_date': '${dateCtrl.text}T00:00:00',
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Create Event', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ),
          ]),
        ),
      ),
    );
  }

  // ── Q&A ────────────────────────────────────────────────────────────────────
  Widget _buildQA() {
    if (_questions.isEmpty) return const MHEmptyState(icon: Icons.forum_rounded, title: 'No Questions Yet', description: 'Be the first to ask a question!');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _questions.length,
        itemBuilder: (ctx, i) {
          final q = _questions[i];
          final answers = q['answers'] as List? ?? [];
          return MHCard(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Center(child: Text('Q', style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.w800, fontSize: 18))),
              ),
              title: Text(q['text'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['author_name'] ?? 'Anonymous', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (q['author_role'] != null && q['author_role'] != 'User')
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(q['author_role'], style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    SizedBox(height: 8),
                    Text('${answers.length} answers', style: TextStyle(color: Color(0xFF007AFF), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              children: [
                ...answers.map<Widget>((a) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Center(child: Text('A', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 14))),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['author_name'] ?? 'Anonymous', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                            if (a['author_role'] != null && a['author_role'] != 'User')
                              Text(a['author_role'], style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(a['text'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.4)),
                          ],
                        ),
                      )
                    ],
                  )
                )),
                InkWell(
                  onTap: () => _showAnswerDialog(q['id']),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.reply_rounded, color: Color(0xFF007AFF), size: 18),
                        SizedBox(width: 8),
                        Text('Add Answer', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateQuestionDialog() {
    final ctrl = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Ask the Community', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 20),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Your Question *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 3),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSubmitting ? null : () async {
                  if (ctrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/questions', data: {'text': ctrl.text});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Post Question', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ),
          ]),
        ),
      ),
    );
  }

  void _showAnswerDialog(int questionId) {
    final ctrl = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Your Answer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 20),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Write your answer...', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 3),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSubmitting ? null : () async {
                  if (ctrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/questions/$questionId/answers', data: {'text': ctrl.text});
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Submit Answer', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ),
          ]),
        ),
      ),
    );
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  Widget _buildChatRooms() {
    if (_chatRooms.isEmpty) return _emptyState(Icons.chat_bubble_outline_rounded, 'No rooms yet');
    
    // Icon mapping logic
    IconData getIconForName(String? iconName) {
      switch(iconName) {
        case 'campaign': return Icons.campaign_rounded;
        case 'account_balance': return Icons.account_balance_rounded;
        case 'shopping_bag': return Icons.shopping_bag_rounded;
        case 'event': return Icons.event_rounded;
        case 'help': return Icons.help_outline_rounded;
        default: return Icons.chat_bubble_outline_rounded;
      }
    }

    return ListView.builder(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: _chatRooms.length,
      itemBuilder: (ctx, i) {
        final room = _chatRooms[i];
        final isOfficial = ['Announcements', 'Government Updates'].contains(room['name']);
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
            border: isOfficial ? Border.all(color: const Color(0xFF007AFF).withOpacity(0.3), width: 1) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openChatRoom(room),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isOfficial ? const Color(0xFF007AFF).withOpacity(0.1) : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        getIconForName(room['icon']),
                        color: isOfficial ? const Color(0xFF007AFF) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(room['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                              if (isOfficial) ...[
                                SizedBox(width: 6),
                                Icon(Icons.verified_rounded, color: Color(0xFF007AFF), size: 16),
                              ]
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            room['description'] ?? '',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreateChatRoomDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSubmitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Create Custom Chat Room', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 8),
            Text('Authorized Roles Only', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 12)),
            SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Room Name *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
            SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 2),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: isSubmitting ? null : () async {
                  if (nameCtrl.text.isEmpty) return;
                  setMBS(() => isSubmitting = true);
                  try {
                    await ApiClient.dio.post('/community/chat/rooms', data: {
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'icon': 'chat'
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Only Admins can create rooms')));
                    setMBS(() => isSubmitting = false);
                  }
                },
                child: isSubmitting ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.surface)) : Text('Create Room', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ),
          ]),
        ),
      ),
    );
  }

  void _openChatRoom(Map<String, dynamic> room) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatRoomScreen(room: room),
    ));
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
      SizedBox(height: 16),
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 18, fontWeight: FontWeight.w600)),
    ]));
  }
}
