import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';
import 'chat_provider.dart';

/// Customer ki taraf se conversation — premium bubbles,
/// date dividers, photo messages, live reply.
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

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    // Ye thread khuli hai — iska banner skip hoga
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
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final error =
        await _provider.sendMessage(chatId: widget.chatId, text: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _msgCtrl.clear();
    } else {
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
    final error =
        await _provider.sendMessage(chatId: widget.chatId, imageFile: picked);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
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

  Widget _bubble(ChatMessage m, bool mine, int index) {
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
                    child: CachedNetworkImage(
                      imageUrl: m.imageUrl,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  )
                : Text(m.text, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(_clock(m.createdAt),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
        begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
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
