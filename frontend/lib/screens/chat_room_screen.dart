import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../api_client.dart';
import '../providers/auth_provider.dart';
import '../services/socket_service.dart';

// ─── ChatRoomScreen ─────────────────────────────────────────────────────────
class ChatRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> room;
  const ChatRoomScreen({super.key, required this.room});
  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  final List<StreamSubscription> _subs = [];
  Map<String, DateTime> _typingUsers = {};
  Timer? _typingTimer;
  bool _isMeTyping = false;
  List<String> _mentionSuggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _connectSocket();
    _msgCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    final text = _msgCtrl.text;
    final cursor = _msgCtrl.selection.baseOffset;
    if (cursor > 0) {
      final before = text.substring(0, cursor);
      final atIdx = before.lastIndexOf('@');
      if (atIdx >= 0 && !before.substring(atIdx).contains(' ')) {
        _fetchMentionSuggestions(before.substring(atIdx + 1).toLowerCase());
      } else if (_mentionSuggestions.isNotEmpty) {
        setState(() => _mentionSuggestions = []);
      }
    }
    final socket = SocketService();
    if (!socket.isConnected) return;
    if (!_isMeTyping) {
      _isMeTyping = true;
      socket.sendTyping(widget.room['id'] as int, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isMeTyping = false;
      socket.sendTyping(widget.room['id'] as int, false);
    });
  }

  Future<void> _fetchMentionSuggestions(String q) async {
    if (q.isEmpty) { setState(() => _mentionSuggestions = []); return; }
    try {
      final r = await ApiClient.dio.get('/users/search', queryParameters: {'q': q});
      final results = r.data as List;
      setState(() {
        _mentionSuggestions = results
            .where((u) => u['username'] != null)
            .map<String>((u) => u['username'] as String)
            .take(5).toList();
      });
    } catch (_) {}
  }

  void _applyMention(String username) {
    final text = _msgCtrl.text;
    final cursor = _msgCtrl.selection.baseOffset;
    final before = text.substring(0, cursor);
    final atIdx = before.lastIndexOf('@');
    final after = text.substring(cursor);
    final newText = '${before.substring(0, atIdx)}@$username $after';
    _msgCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIdx + username.length + 2),
    );
    setState(() => _mentionSuggestions = []);
  }

  void _connectSocket() {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn || auth.token == null) return;
    final socket = SocketService();
    socket.connect(auth.token!);
    WidgetsBinding.instance.addPostFrameCallback((_) => socket.joinRoom(widget.room['id'] as int));

    _subs.add(socket.onNewMessage.listen((msgData) {
      if (msgData['room_id'] == widget.room['id'] && mounted) {
        final clientId = msgData['client_msg_id'];
        final exists = _messages.any((m) {
          final id = m['id'];
          return (id is int && id > 0 && id == msgData['id']);
        });
        if (!exists) {
          setState(() {
            _messages.removeWhere((m) =>
                (clientId != null && m['client_msg_id'] == clientId) ||
                (m['id'] is String && (m['id'] as String).startsWith('temp_') && m['content'] == msgData['content']));
            _messages.add(msgData);
          });
        }
      }
    }));

    _subs.add(socket.onMessageConfirmed.listen((data) {
      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == data['temp_id']);
        if (idx >= 0) _messages[idx] = {..._messages[idx], 'id': data['real_id']};
      });
    }));

    _subs.add(socket.onTyping.listen((data) {
      if (data['room_id'] == widget.room['id'] && mounted) {
        final who = data['username'] ?? data['display_name'] ?? 'Someone';
        final isTyping = data['is_typing'] as bool? ?? true;
        setState(() { isTyping ? _typingUsers[who] = DateTime.now() : _typingUsers.remove(who); });
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _typingTimer?.cancel();
    SocketService().leaveRoom(widget.room['id'] as int);
    _msgCtrl.removeListener(_onTextChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final r = await ApiClient.dio.get('/community/chat/rooms/${widget.room['id']}/messages');
      if (mounted) setState(() { _messages = r.data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _mentionSuggestions = []);
    final auth = ref.read(authProvider);
    final myId = auth.user?['id'];
    final myName = auth.user?['display_name'] ?? auth.user?['username'] ?? 'You';
    final roomId = widget.room['id'] as int;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId, 'client_msg_id': tempId, 'sender_id': myId,
      'content': text, 'room_id': roomId,
      'created_at': DateTime.now().toIso8601String(),
      'sender_name': myName, 'display_name': myName,
      'username': auth.user?['username'],
      'sender_role': auth.user?['role']?['name'],
      'sender_avatar': auth.user?['profile']?['avatar_url'],
      '_pending': true,
    };
    setState(() => _messages.add(tempMsg));
    final socket = SocketService();
    if (socket.isConnected) {
      socket.sendMessage(roomId, text, clientMsgId: tempId);
    } else {
      try {
        final r = await ApiClient.dio.post('/community/chat/rooms/$roomId/messages', data: {'content': text});
        if (mounted) setState(() { _messages.removeWhere((m) => m['id'] == tempId); _messages.add(r.data); });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  String get _typingText {
    final active = _typingUsers.entries
        .where((e) => DateTime.now().difference(e.value).inSeconds < 5)
        .map((e) => e.key).toList();
    if (active.isEmpty) return '';
    return active.length == 1 ? '${active[0]} is typing…' : '${active.join(', ')} are typing…';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final myId = auth.user?['id'] as int?;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.room['name'] ?? 'Chat', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (widget.room['description'] != null)
            Text(widget.room['description'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMessages)],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = _messages[_messages.length - 1 - i];
                    return _buildBubble(msg, msg['sender_id'] == myId, isDark);
                  },
                ),
        ),
        if (_typingText.isNotEmpty)
          Container(
            width: double.infinity,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(_typingText, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        if (_mentionSuggestions.isNotEmpty)
          Container(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _mentionSuggestions.length,
              itemBuilder: (ctx, i) => ListTile(
                dense: true,
                leading: const Icon(Icons.alternate_email, size: 18),
                title: Text('@${_mentionSuggestions[i]}'),
                onTap: () => _applyMention(_mentionSuggestions[i]),
              ),
            ),
          ),
        if (auth.isLoggedIn)
          SafeArea(
            top: false,
            child: Container(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Message… (@ to mention)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 6),
                FloatingActionButton.small(
                  heroTag: 'chat_send',
                  onPressed: _send,
                  child: const Icon(Icons.send, size: 20),
                ),
              ]),
            ),
          )
        else
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(12),
            child: const Text('Login to send messages', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, bool isDark) {
    final isPending = msg['_pending'] == true;
    final senderName = msg['display_name'] ?? msg['sender_name'] ?? '';
    final username = msg['username'] as String?;
    final role = msg['sender_role'] as String?;
    final mentions = (msg['mentions'] as List?)?.cast<String>() ?? [];
    final image_urls = (msg['image_urls'] as List?)?.cast<String>() ?? [];
    final translated_text = msg['translated_text'] as Map<String, dynamic>? ?? {};
    final reactions = msg['reactions'] as Map<String, dynamic>? ?? {};
    final isPinned = msg['is_pinned'] == true;
    final status = msg['status'] as String? ?? 'sent';
    
    final timeStr = () {
      final raw = msg['created_at']?.toString() ?? '';
      return raw.length >= 16 ? raw.substring(11, 16) : '';
    }();
    Color? roleBadgeColor;
    if (role == 'Super Admin') roleBadgeColor = Colors.red;
    else if (role == 'Admin') roleBadgeColor = Colors.orange;
    else if (role == 'Moderator') roleBadgeColor = Colors.purple;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: msg['sender_avatar'] != null ? NetworkImage(msg['sender_avatar']) : null,
              backgroundColor: Colors.blueGrey.shade200,
              child: msg['sender_avatar'] == null ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).colorScheme.primary : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isPinned) ...[
                  Row(children: [
                    Icon(Icons.push_pin, size: 12, color: isMe ? Colors.white70 : Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text('Pinned', style: TextStyle(color: isMe ? Colors.white70 : Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                ],
                
                if (!isMe) ...[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (username != null) Text('@$username', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                    if (username != null && senderName.isNotEmpty && senderName != username)
                      Text(' · $senderName', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (roleBadgeColor != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: roleBadgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: roleBadgeColor, width: 0.5)),
                        child: Text(role!, style: TextStyle(color: roleBadgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                ],
                
                if (image_urls.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(image_urls[0], height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                  ),
                  const SizedBox(height: 4),
                ],
                
                if ((msg['content'] ?? '').isNotEmpty)
                  _buildContent(msg['content'] ?? '', isMe, mentions),
                  
                if (translated_text.isNotEmpty && translated_text['en'] != null && translated_text['en'] != msg['content']) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                    child: Text(translated_text['en'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade700, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
                
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(timeStr, style: TextStyle(color: isMe ? Colors.white60 : Colors.grey.shade500, fontSize: 10)),
                  if (isPending) ...[const SizedBox(width: 4), Icon(Icons.access_time, size: 10, color: isMe ? Colors.white60 : Colors.grey)],
                  if (!isPending && isMe) ...[
                    const SizedBox(width: 4),
                    Icon(status == 'seen' ? Icons.done_all : Icons.check, size: 12, color: status == 'seen' ? Colors.blue.shade200 : Colors.white60)
                  ],
                ]),
                
                if (reactions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: reactions.entries.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('${e.key} ${(e.value as List).length}', style: TextStyle(fontSize: 10, color: isMe ? Colors.white : Colors.black87)),
                    )).toList(),
                  )
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String content, bool isMe, List<String> mentions) {
    if (mentions.isEmpty) return Text(content, style: TextStyle(color: isMe ? Colors.white : null));
    final spans = <TextSpan>[];
    final parts = content.split(RegExp(r'(@\w+)'));
    for (final part in parts) {
      final isMention = part.startsWith('@') && mentions.contains(part.substring(1));
      spans.add(TextSpan(
        text: part,
        style: isMention
            ? TextStyle(color: isMe ? Colors.yellowAccent : Colors.blue.shade700, fontWeight: FontWeight.bold)
            : TextStyle(color: isMe ? Colors.white : null),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
