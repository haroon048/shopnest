import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopnest/models/chat_message.dart';
import 'admin_chat_provider.dart';

// Admin ki taraf se conversation — premium bubbles, date dividers,
// timestamps, live reply + naya message aate hi auto-scroll.
class AdminChatThreadScreen extends StatefulWidget {
  final String chatId;
  final String title;
  const AdminChatThreadScreen(
      {super.key, required this.chatId, required this.title});

  @override
  State<AdminChatThreadScreen> createState() => _AdminChatThreadScreenState();
}

class _AdminChatThreadScreenState extends State<AdminChatThreadScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  int _msgCount = 0;
  late final AdminChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AdminChatProvider>();
    // Ye thread khuli hai — iska notification banner skip hoga
    _provider.openChatId = widget.chatId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _provider.markAsRead(widget.chatId, uid);
    }
  }

  @override
  void dispose() {
    _provider.openChatId = null;
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Naya message aaye to sab se neeche le jao (reverse list me 0 = neeche)
  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    setState(() => _sending = true);
    final senderName = (fbUser.displayName?.isNotEmpty ?? false)
        ? fbUser.displayName!
        : 'Admin';
    final error = await _provider.sendReply(
      chatId: widget.chatId,
      senderId: fbUser.uid,
      senderName: senderName,
      text: text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _msgCtrl.clear();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _clock(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.person_outline,
                  color: Color(0xFF8B5CF6), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _provider.messagesStream(widget.chatId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final msgs = snap.data ?? [];
                    // Naya message aaya to auto-scroll neeche
                    if (msgs.length != _msgCount) {
                      _msgCount = msgs.length;
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToBottom());
                    }
                    if (msgs.isEmpty) {
                      return const Center(
                          child: Text('No messages yet. Say hello!',
                              style: TextStyle(color: Colors.white54)));
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) {
                        final m = msgs[msgs.length - 1 - i];
                        final prev = (msgs.length - 1 - i) > 0
                            ? msgs[msgs.length - 2 - i]
                            : null;
                        return Column(
                          children: [
                            _dayDivider(m.createdAt, prev?.createdAt),
                            _bubble(m, m.senderId == myId),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _inputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayDivider(DateTime? cur, DateTime? prev) {
    if (cur == null) return const SizedBox.shrink();
    final sameDay = prev != null &&
        cur.year == prev.year &&
        cur.month == prev.month &&
        cur.day == prev.day;
    if (sameDay) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(_dayLabel(cur),
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          gradient: mine
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
              : null,
          color: mine ? null : Colors.white.withValues(alpha: 0.07),
          border: mine
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: mine
              ? [
                  BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(m.senderName,
                    style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            m.type == 'image' && m.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(m.imageUrl),
                  )
                : Text(m.text, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(_clock(m.createdAt),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a reply...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 14),
                  ],
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
