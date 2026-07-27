import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../services/socket_service.dart';
import 'chat_room_screen.dart';

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
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/community/polls'),
        ApiClient.dio.get('/community/events'),
        ApiClient.dio.get('/community/questions'),
        ApiClient.dio.get('/community/chat/rooms'),
      ]);
      setState(() {
        _polls = results[0].data;
        _events = results[1].data;
        _questions = results[2].data;
        _chatRooms = results[3].data;
      });
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(ref, 'Community Hub')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.how_to_vote, size: 18), text: 'Polls'),
            Tab(icon: Icon(Icons.event, size: 18), text: 'Events'),
            Tab(icon: Icon(Icons.forum, size: 18), text: 'Q&A'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Chat'),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 0: _showCreatePollDialog(); break;
          case 1: _showCreateEventDialog(); break;
          case 2: _showCreateQuestionDialog(); break;
        }
      },
      child: const Icon(Icons.add),
    );
  }

  // ── Polls ──────────────────────────────────────────────────────────────────
  Widget _buildPolls() {
    if (_polls.isEmpty) return _emptyState(Icons.how_to_vote, 'No polls yet');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _polls.length,
        itemBuilder: (ctx, i) => _buildPollCard(_polls[i]),
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll) {
    final options = (poll['options'] as List? ?? []);
    final totalVotes = options.fold<int>(0, (sum, o) => sum + (o['vote_count'] as int? ?? 0));
    final votedId = poll['user_voted_option_id'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...options.map<Widget>((opt) {
              final votes = opt['vote_count'] as int? ?? 0;
              final pct = totalVotes > 0 ? votes / totalVotes : 0.0;
              final isVoted = votedId == opt['id'];
              return InkWell(
                onTap: votedId != null ? null : () => _castVote(poll['id'], opt['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(opt['text'] ?? '', style: TextStyle(fontWeight: isVoted ? FontWeight.bold : FontWeight.normal)),
                        Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: isVoted ? Colors.blue : Colors.blue.shade200,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            Text('$totalVotes votes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Create a Poll', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Poll Question *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: option1, decoration: const InputDecoration(labelText: 'Option 1 *', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: option2, decoration: const InputDecoration(labelText: 'Option 2 *', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: option3, decoration: const InputDecoration(labelText: 'Option 3 (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final options = [option1.text, option2.text, if (option3.text.isNotEmpty) option3.text];
              if (questionCtrl.text.isEmpty || options.length < 2) return;
              try {
                await ApiClient.dio.post('/community/polls', data: {'question': questionCtrl.text, 'options': options});
                Navigator.pop(ctx);
                _fetchAll();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: const Text('Create Poll'),
          )),
        ]),
      ),
    );
  }

  // ── Events ─────────────────────────────────────────────────────────────────
  Widget _buildEvents() {
    if (_events.isEmpty) return _emptyState(Icons.event, 'No events yet');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _events.length,
        itemBuilder: (ctx, i) {
          final event = _events[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event['image_url'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(event['image_url'], width: double.infinity, height: 160, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (event['event_date'] != null)
                      Row(children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(event['event_date'].toString().substring(0, 10), style: const TextStyle(color: Colors.grey)),
                      ]),
                    if (event['location_name'] != null)
                      Row(children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(event['location_name'], style: const TextStyle(color: Colors.grey)),
                      ]),
                    if (event['description'] != null) ...[const SizedBox(height: 8), Text(event['description'])],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Create Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
              try {
                await ApiClient.dio.post('/community/events', data: {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'location_name': locationCtrl.text,
                  'event_date': '${dateCtrl.text}T00:00:00',
                });
                Navigator.pop(ctx);
                _fetchAll();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: const Text('Create Event'),
          )),
        ]),
      ),
    );
  }

  // ── Q&A ────────────────────────────────────────────────────────────────────
  Widget _buildQA() {
    if (_questions.isEmpty) return _emptyState(Icons.forum, 'No questions yet');
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _questions.length,
        itemBuilder: (ctx, i) {
          final q = _questions[i];
          final answers = q['answers'] as List? ?? [];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade100,
                child: Text('Q', style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold)),
              ),
              title: Text(q['text'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q['author_name'] ?? 'Anonymous', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                  if (q['author_role'] != null && q['author_role'] != 'User')
                    Text(q['author_role'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${answers.length} answers', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              children: [
                ...answers.map<Widget>((a) => ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Text('A', style: TextStyle(color: Colors.white))),
                  title: Text(a['text'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['author_name'] ?? 'Anonymous', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                      if (a['author_role'] != null && a['author_role'] != 'User')
                        Text(a['author_role'], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                )),
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.blue),
                  title: const Text('Add Answer', style: TextStyle(color: Colors.blue)),
                  onTap: () => _showAnswerDialog(q['id']),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Ask the Community', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Your Question *', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await ApiClient.dio.post('/community/questions', data: {'text': ctrl.text});
                Navigator.pop(ctx);
                _fetchAll();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: const Text('Post Question'),
          )),
        ]),
      ),
    );
  }

  void _showAnswerDialog(int questionId) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Your Answer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Write your answer...', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await ApiClient.dio.post('/community/questions/$questionId/answers', data: {'text': ctrl.text});
                Navigator.pop(ctx);
                _fetchAll();
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: const Text('Submit Answer'),
          )),
        ]),
      ),
    );
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  Widget _buildChatRooms() {
    if (_chatRooms.isEmpty) return _emptyState(Icons.chat_bubble_outline, 'No rooms yet');
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _chatRooms.length,
      itemBuilder: (ctx, i) {
        final room = _chatRooms[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.chat, color: Colors.blue.shade900),
            ),
            title: Text(room['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(room['description'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openChatRoom(room),
          ),
        );
      },
    );
  }

  void _openChatRoom(Map<String, dynamic> room) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatRoomScreen(room: room),
    ));
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text(text, style: const TextStyle(color: Colors.grey, fontSize: 18)),
    ]));
  }
}
