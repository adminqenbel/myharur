import 'package:flutter/material.dart';

class TownChatPage extends StatefulWidget {
  const TownChatPage({super.key});

  @override
  State<TownChatPage> createState() => _TownChatPageState();
}

class _TownChatPageState extends State<TownChatPage> {
  int selectedRoom = 0;
  final rooms = [
    {'name': 'Public Town Chat', 'type': 'public', 'icon': 'chat', 'color': Color(0xFF007F63)},
    {'name': 'Government & Collector Updates', 'type': 'gov', 'icon': 'news', 'color': Color(0xFF267AF4)},
    {'name': 'Cricket Tournament (Event Room)', 'type': 'event', 'icon': 'calendar', 'color': Color(0xFFF59E0B)},
  ];

  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'Muthuvel K.',
      'mmid': '20260814-4821',
      'role': 'Resident',
      'text': 'Good morning everyone! Is the water supply scheduled for Ward 4 today?',
      'time': '9:15 AM',
      'isGov': false,
    },
    {
      'sender': 'Panchayat Officer',
      'mmid': 'AID-HR-0012',
      'role': 'Government Official',
      'text': '@Muthuvel Yes, overhead tank pumping will begin at 10:30 AM across Wards 4 and 5.',
      'time': '9:18 AM',
      'isGov': true,
    },
    {
      'sender': 'Selvam Agro',
      'mmid': '20260814-1109',
      'role': 'Shop Admin',
      'text': 'Fresh bio-fertilizer stock arrived at Bazaar shop. 15% discount for local farmers today.',
      'time': '9:42 AM',
      'isGov': false,
    },
  ];

  final _textCtrl = TextEditingController();

  void _sendMessage() {
    if (_textCtrl.text.trim().isEmpty) return;
    setState(() {
      messages.add({
        'sender': 'You (Resident)',
        'mmid': '20260814-8890',
        'role': 'Resident',
        'text': _textCtrl.text.trim(),
        'time': 'Now',
        'isGov': false,
      });
      _textCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRoom = rooms[selectedRoom];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentRoom['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF15211F)),
            ),
            const Text(
              'Super Admin Supervised · Anti-Abuse Protected',
              style: TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Room switcher strip
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFF2F6F5),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedRoom == i;
                  return ChoiceChip(
                    label: Text(rooms[i]['name'] as String),
                    selected: active,
                    onSelected: (_) => setState(() => selectedRoom = i),
                    selectedColor: const Color(0xFF007F63),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF15211F),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  );
                },
              ),
            ),

            // Messages Stream
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isGov = msg['isGov'] == true;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isGov ? const Color(0xFFE9F6F1) : const Color(0xFFF9FBFA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isGov ? const Color(0xFF9DD8C5) : const Color(0xFFE2EBE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              msg['sender'],
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF15211F)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isGov ? const Color(0xFF007F63) : const Color(0xFF697570),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                msg['role'],
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              msg['time'],
                              style: const TextStyle(fontSize: 10, color: Color(0xFF697570), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg['text'],
                          style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF15211F)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFDCE5E1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDCE5E1)),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type message or @username to tag...',
                          hintStyle: TextStyle(color: Color(0xFF697570), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
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
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
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
}
