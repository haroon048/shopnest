import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';
import 'chat_provider.dart';

/// E-commerce chat — product context, ticks, reply, delete,
/// typing indicator, quick replies. Daraz/Amazon style.
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  late final ChatProvider _provider;

  // Reply: jis message ka jawab de rahe hain
  ChatMessage? _replyingTo;
  // Main buyer hun ya seller (quick replies sirf buyer ko)
  bool _isBuyer = false;
  String _productId = '';
  // Saamne wala typing kar raha hai?
  bool _otherTyping = false;
  StreamSubscription<String>? _typingSub;
  Timer? _typingTimer;

  // E-commerce quick replies (buyer ke liye)
  static const _quickReplies = [
    'Is this available?',
    'What is the delivery time?',
    'Is there any discount?',
    'Is this original?',
  ];

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    // Ye thread khuli hai — iska banner skip hoga
    _provider.openChatId = widget.chatId;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _provider.markAsSeen(widget.chatId, uid);
    }
    // Buyer/product maloom karo + typing suno
    _provider.getThread(widget.chatId).then((t) {
      if (mounted && t != null) {
        setState(() {
          _isBuyer = t.buyerId == uid;
          _productId = t.productId;
        });
      }
    });
    _typingSub = _provider.typingStream(widget.chatId).listen((typingBy) {
      final typing = typingBy.isNotEmpty && typingBy != uid;
      if (mounted && typing != _otherTyping) {
        setState(() => _otherTyping = typing);
      }
    });
  }

  @override
  void dispose() {
    _provider.openChatId = null;
    _provider.setTyping(widget.chatId, false);
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  // Text likhte waqt typing bhejo, 2 sec rukne par band
  void _onTextChanged(String text) {
    if (text.isEmpty) {
      _provider.setTyping(widget.chatId, false);
      _typingTimer?.cancel();
      return;
    }
    _provider.setTyping(widget.chatId, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _provider.setTyping(widget.chatId, false);
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final reply = _replyingTo;
    final error = await _provider.sendMessage(
      chatId: widget.chatId,
      text: text,
      replyTo: reply,
    );
    _provider.setTyping(widget.chatId, false);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _replyingTo = null;
    });
    if (error == null) {
      _msgCtrl.clear();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _sendQuickReply(String text) async {
    if (_sending) return;
    setState(() => _sending = true);
    final error =
        await _provider.sendMessage(chatId: widget.chatId, text: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _sendPhoto() async {
    if (_sending) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _sending = true);
    final reply = _replyingTo;
    final error = await _provider.sendMessage(
      chatId: widget.chatId,
      imageFile: picked,
      replyTo: reply,
    );
    _provider.setTyping(widget.chatId, false);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _replyingTo = null;
    });
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // ---------- Long-press menu ----------
  void _showMessageMenu(ChatMessage m, bool mine) {
    if (m.deletedForEveryone) return; // delete hua message — menu nahi
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _menuItem(
              icon: Icons.reply_outlined,
              label: 'Reply',
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = m);
              },
            ),
            _menuItem(
              icon: Icons.copy_outlined,
              label: 'Copy',
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(
                    ClipboardData(text: m.isImage ? m.imageUrl : m.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              },
            ),
            _menuItem(
              icon: Icons.delete_outline,
              label: 'Delete for me',
              onTap: () {
                Navigator.pop(ctx);
                _provider.deleteMessageForMe(widget.chatId, m.id);
              },
            ),
            if (mine)
              _menuItem(
                icon: Icons.delete_forever_outlined,
                label: 'Delete for everyone',
                danger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _provider.deleteMessageForEveryone(widget.chatId, m.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.redAccent : Colors.white70),
      title: Text(label,
          style: TextStyle(color: danger ? Colors.redAccent : Colors.white)),
      onTap: onTap,
    );
  }

  // ---------- Clear chat (confirm) ----------
  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear chat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All messages will be removed for you. The other person will still see them.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _provider.clearChat(widget.chatId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared')),
        );
      }
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _provider.threadStream(widget.chatId),
          builder: (context, snap) {
            final data = snap.data?.data();
            final title = data?['productName'] as String? ?? 'Chat';
            final img = data?['productImage'] as String? ?? '';
            return Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: ClipOval(
                    child: img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primaryViolet
                                  .withValues(alpha: 0.15),
                              child: const Icon(Icons.chat_bubble_outline,
                                  color: AppColors.primaryViolet, size: 20),
                            ),
                          )
                        : Container(
                            color:
                                AppColors.primaryViolet.withValues(alpha: 0.15),
                            child: const Icon(Icons.chat_bubble_outline,
                                color: AppColors.primaryViolet, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'clear') _clearChat();
              if (v == 'product' && _productId.isNotEmpty) {
                Navigator.pushNamed(context, AppRoutes.productDetail,
                    arguments: _productId);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'product',
                child:
                    Text('View product', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryViolet.withValues(alpha: 0.08),
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
                color: AppColors.accent.withValues(alpha: 0.06),
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
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primaryViolet));
                    }
                    final msgs = snap.data ?? [];
                    // Naye messages aaye to seen mark karo
                    final unseen = msgs
                        .where((m) => m.senderId != myId && m.status != 'seen');
                    if (unseen.isNotEmpty && myId != null) {
                      _provider.markAsSeen(widget.chatId, myId);
                    }
                    if (msgs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryViolet
                                        .withValues(alpha: 0.25),
                                    AppColors.accent.withValues(alpha: 0.15),
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.chat_bubble_outline,
                                  size: 38, color: AppColors.primaryViolet),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.06, 1.06),
                                    duration: 1600.ms),
                            const SizedBox(height: 14),
                            const Text('Start the conversation',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'Ask about price, delivery\nor anything else.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.easeOutBack);
                    }
                    return ListView.builder(
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
                            _bubble(m, m.senderId == myId, i),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              if (_otherTyping) _typingIndicator(),
              if (_isBuyer) _quickRepliesRow(),
              if (_replyingTo != null) _replyPreview(),
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

  // ---------- Typing indicator ----------
  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.07),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white70,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(delay: (i * 200).ms, duration: 400.ms)
                    .fadeOut(delay: (i * 200 + 400).ms, duration: 400.ms);
              }),
            ),
          ),
          const SizedBox(width: 8),
          const Text('typing...',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  // ---------- Quick replies (buyer ke liye) ----------
  Widget _quickRepliesRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _sendQuickReply(_quickReplies[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                  color: AppColors.primaryViolet.withValues(alpha: 0.4)),
            ),
            child: Text(
              _quickReplies[i],
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Reply preview (input ke upar) ----------
  Widget _replyPreview() {
    final r = _replyingTo!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryViolet.withValues(alpha: 0.12),
        border:
            Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${r.senderName}',
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.isImage ? 'Photo' : r.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, bool mine, int index) {
    // Delete-for-everyone: sirf placeholder dikhao
    if (m.deletedForEveryone) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_outlined, size: 14, color: Colors.white38),
              SizedBox(width: 6),
              Text('This message was deleted',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showMessageMenu(m, mine),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
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
              // Reply quote
              if (m.hasReply)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withValues(alpha: 0.18),
                    border: Border(
                      left: BorderSide(
                        color: mine
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.primaryPink,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.replyToName,
                          style: TextStyle(
                            color: mine
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.primaryPink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 1),
                      Text(m.replyToText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
              m.type == 'image' && m.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: m.imageUrl,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white54),
                      ),
                    )
                  : Text(m.text, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_clock(m.createdAt),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10)),
                  // Ticks — sirf mere messages par
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _ticks(m.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
    );
  }

  // ✓ sent, ✓✓ delivered (grey), ✓✓ seen (pink)
  Widget _ticks(String status) {
    if (status == 'seen') {
      return const Icon(Icons.done_all, size: 14, color: AppColors.primaryPink);
    }
    if (status == 'delivered') {
      return Icon(Icons.done_all,
          size: 14, color: Colors.white.withValues(alpha: 0.6));
    }
    return Icon(Icons.done,
        size: 14, color: Colors.white.withValues(alpha: 0.6));
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
            // Photo button
            GestureDetector(
              onTap: _sendPhoto,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.image_outlined,
                    color: AppColors.primaryViolet, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: AppColors.primaryViolet.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  onChanged: _onTextChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 48,
                height: 48,
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
