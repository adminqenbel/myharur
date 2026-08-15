import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class TownChatPage extends StatefulWidget {
  const TownChatPage({super.key});

  @override
  State<TownChatPage> createState() => _TownChatPageState();
}

class _TownChatPageState extends State<TownChatPage> {
  int selectedRoomIndex = 0;
  final List<Map<String, dynamic>> rooms = [
    {
      'id': 'public_town',
      'name': 'Public Town Chat',
      'icon': Icons.forum_rounded,
      'onlineCount': 148,
      'color': const Color(0xFF007F63),
    },
    {
      'id': 'gov_official',
      'name': 'Govt & Collector Notices',
      'icon': Icons.campaign_rounded,
      'onlineCount': 42,
      'color': const Color(0xFF267AF4),
    },
    {
      'id': 'farmer_agri',
      'name': 'Farmer & KVK Advisory',
      'icon': Icons.agriculture_rounded,
      'onlineCount': 86,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'sports_events',
      'name': 'Sports & Festivals',
      'icon': Icons.sports_cricket_rounded,
      'onlineCount': 64,
      'color': const Color(0xFFE44545),
    },
  ];

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final quickReactions = ['🙏 Vanakkam', '🌾 Agri Update', '📢 Announcement', '🚨 Emergency SOS', '👍 Agreed'];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);
    final room = rooms[selectedRoomIndex]['id'] as String;
    final data = await ChatService.fetchMessages(room);
    if (mounted) {
      setState(() {
        messages = data;
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? customText, String? attachment}) async {
    final text = customText ?? _textCtrl.text.trim();
    if (text.isEmpty && attachment == null) return;

    final room = rooms[selectedRoomIndex]['id'] as String;
    final myProfile = AuthService.currentProfile;

    final newMsg = {
      'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'sender_name': myProfile.fullName,
      'sender_mmid': myProfile.mmid,
      'sender_role': myProfile.role.toUpperCase(),
      'text': text,
      'attachment_url': attachment,
      'created_at': DateTime.now().toIso8601String(),
      'is_official': myProfile.role == 'admin' || myProfile.role == 'superadmin',
      'is_me': true,
    };

    setState(() {
      messages.add(newMsg);
    });
    if (customText == null) _textCtrl.clear();
    _scrollToBottom();

    await ChatService.sendMessage(
      roomName: room,
      text: text,
      attachmentUrl: attachment,
    );
  }

  void _shareLocation() {
    _sendMessage(
      customText: '📍 Shared Location: Harur Town Bus Stand Junction (12.0624° N, 78.4983° E)',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location shared in town chat.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = rooms[selectedRoomIndex];
    final myProfile = AuthService.currentProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (currentRoom['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(currentRoom['icon'] as IconData, color: currentRoom['color'] as Color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentRoom['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF15211F)),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF00D09C), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${currentRoom['onlineCount']} online • MMID Verified',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Channel Switcher Tabs
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedRoomIndex == i;
                  return ChoiceChip(
                    label: Text(rooms[i]['name'] as String),
                    selected: active,
                    onSelected: (_) {
                      setState(() => selectedRoomIndex = i);
                      _loadMessages();
                    },
                    selectedColor: const Color(0xFF007F63),
                    backgroundColor: const Color(0xFFF2F6F5),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF15211F),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(
                      color: active ? const Color(0xFF007F63) : const Color(0xFFDCE5E1),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2EBE8)),

            // Real-Time Chat Message Stream
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF007F63)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        final isMe = msg['is_me'] == true || msg['sender_mmid'] == myProfile.mmid;
                        final isOfficial = msg['is_official'] == true || msg['sender_role'] == 'GOVERNMENT OFFICIAL' || msg['sender_role'] == 'SUPERADMIN';

                        return _buildChatBubble(msg, isMe, isOfficial);
                      },
                    ),
            ),

            // Quick Reaction Chips
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickReactions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: const Color(0xFFF2F6F5),
                    label: Text(quickReactions[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15211F))),
                    onPressed: () => _sendMessage(customText: quickReactions[i]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFDCE5E1)),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2EBE8))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.pin_drop_rounded, color: Color(0xFF007F63), size: 22),
                    tooltip: 'Share Landmark / Location',
                    onPressed: _shareLocation,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDCE5E1)),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Message Harur neighbours...',
                          hintStyle: TextStyle(color: Color(0xFF697570), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF007F63),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe, bool isOfficial) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isOfficial ? const Color(0xFF007F63) : const Color(0xFFE0EAE6),
              child: Text(
                msg['sender_name'] != null && msg['sender_name'].toString().isNotEmpty
                    ? msg['sender_name'][0].toUpperCase()
                    : 'R',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isOfficial ? Colors.white : const Color(0xFF007F63),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF0E261F)
                    : (isOfficial ? const Color(0xFFE9F6F1) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF00D09C).withValues(alpha: 0.3)
                      : (isOfficial ? const Color(0xFF81C784) : const Color(0xFFE2EBE8)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg['sender_name'] ?? 'Resident',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF15211F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isOfficial ? const Color(0xFF007F63) : const Color(0xFFE2EBE8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            msg['sender_role'] ?? 'RESIDENT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isOfficial ? Colors.white : const Color(0xFF52615B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: isMe ? Colors.white : const Color(0xFF15211F),
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Just now',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? const Color(0xFF8E9F98) : const Color(0xFF9EAEA8),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF00D09C)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
