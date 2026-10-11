import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shopnest/models/chat_message.dart';
import 'admin_chat_provider.dart';
import 'admin_chat_thread_screen.dart';

// Premium messenger-style chat list: gradient title, floating search,
// All/Unread pills, springy row animations, pulsing unread badges.
class AdminChatsScreen extends StatefulWidget {
  const AdminChatsScreen({super.key});

  @override
  State<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends State<AdminChatsScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  bool _unreadOnly = false;
  bool _searchFocused = false;

  StreamSubscription<ChatNotificationEvent>? _notifSub;
  ChatNotificationEvent? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final provider = context.read<AdminChatProvider>();
    provider.startNotifications(myUid);
    _notifSub = provider.notificationsStream.listen((event) {
      if (!mounted) return;
      setState(() => _banner = event);
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _banner = null);
      });
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _bannerTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openThread(String chatId, String title) {
    setState(() => _banner = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminChatThreadScreen(chatId: chatId, title: title),
      ),
    );
  }

  String _time(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final provider = context.read<AdminChatProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      body: Stack(
        children: [
          // Ambient glow orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            child: StreamBuilder<List<ChatThread>>(
              stream: provider.threadsStream,
              builder: (context, threadSnap) {
                if (threadSnap.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      _header(0, 0),
                      _searchBar(),
                      _filterPills(0),
                      Expanded(child: _skeleton()),
                    ],
                  );
                }
                var all = threadSnap.data ?? [];
                if (_query.isNotEmpty) {
                  all = all.where((t) {
                    final hay =
                        '${t.productName ?? ''} ${t.lastMessage}'.toLowerCase();
                    return hay.contains(_query.toLowerCase());
                  }).toList();
                }
                return StreamBuilder<Map<String, int>>(
                  stream: provider.unreadMapStream(myUid),
                  builder: (context, unreadSnap) {
                    final unread = unreadSnap.data ?? {};
                    final unreadTotal = unread.values.fold(0, (a, b) => a + b);
                    var threads = all;
                    if (_unreadOnly) {
                      threads = threads
                          .where((t) => (unread[t.id] ?? 0) > 0)
                          .toList();
                    }
                    return Column(
                      children: [
                        _header(all.length, unreadTotal),
                        if (_banner != null) _notificationBanner(),
                        _searchBar(),
                        _filterPills(unreadTotal),
                        Expanded(
                          child: threads.isEmpty
                              ? _emptyState()
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.only(top: 6, bottom: 16),
                                  itemCount: threads.length,
                                  separatorBuilder: (_, __) => Padding(
                                    padding: const EdgeInsets.only(left: 96),
                                    child: Divider(
                                        height: 1,
                                        color: Colors.white
                                            .withValues(alpha: 0.06)),
                                  ),
                                  itemBuilder: (context, i) => _row(
                                      context,
                                      threads[i],
                                      unread[threads[i].id] ?? 0,
                                      i),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Header ----------

  Widget _header(int total, int unreadTotal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ).createShader(bounds),
            child: const Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unreadTotal > 0
                ? '$total conversations · $unreadTotal unread'
                : '$total conversations',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.4, end: 0, duration: 400.ms);
  }

  // ---------- Floating search ----------

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: _searchFocused
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: _searchFocused
              ? [
                  BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      blurRadius: 18),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search conversations',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon:
                const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Colors.white38, size: 20),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.4, end: 0, duration: 400.ms);
  }

  // ---------- All / Unread pills ----------

  Widget _filterPills(int unreadTotal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
                child: _pill('All', !_unreadOnly,
                    () => setState(() => _unreadOnly = false))),
            Expanded(
                child: _pill(
                    unreadTotal > 0 ? 'Unread ($unreadTotal)' : 'Unread',
                    _unreadOnly,
                    () => setState(() => _unreadOnly = true))),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 180.ms, duration: 400.ms)
        .slideY(begin: 0.4, end: 0, duration: 400.ms);
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      blurRadius: 12),
                ]
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ),
      ),
    );
  }

  // ---------- Chat row (messenger style) ----------

  Widget _row(BuildContext context, ChatThread thread, int unread, int index) {
    final title = thread.productName ?? 'Chat';
    return GestureDetector(
      onTap: () => _openThread(thread.id, title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            _avatar(thread, unread > 0),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600)),
                      ),
                      Text(_time(thread.lastMessageAt),
                          style: TextStyle(
                              color: unread > 0
                                  ? const Color(0xFFEC4899)
                                  : Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white
                                    .withValues(alpha: unread > 0 ? 0.85 : 0.5),
                                fontSize: 14)),
                      ),
                      if (unread > 0) _unreadPill(unread),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (70 * index).ms, duration: 450.ms)
        .slideX(
            begin: 0.25,
            end: 0,
            delay: (70 * index).ms,
            duration: 450.ms,
            curve: Curves.easeOutCubic)
        .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            delay: (70 * index).ms,
            duration: 450.ms);
  }

  Widget _avatar(ChatThread thread, bool highlight) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: highlight
                ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                : [
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.08)
                  ]),
      ),
      child: ClipOval(
        child: (thread.productImage ?? '').isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thread.productImage,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _avatarFallback(),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
      child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF8B5CF6)),
    );
  }

  // Pulsing unread badge.
  Widget _unreadPill(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.5),
              blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.12, 1.12),
        duration: 700.ms,
        curve: Curves.easeInOut);
  }

  // ---------- Shimmer loading ----------

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white10)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Colors.white10)),
                const SizedBox(height: 8),
                Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white10)),
              ])),
        ]),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1400.ms, color: Colors.white.withValues(alpha: 0.12));
  }

  // ---------- Empty states ----------

  Widget _emptyState() {
    final unreadMode = _unreadOnly;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                const Color(0xFFEC4899).withValues(alpha: 0.15),
              ]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    blurRadius: 24),
              ],
            ),
            child: Icon(
                unreadMode
                    ? Icons.check_circle_outline
                    : Icons.chat_bubble_outline,
                size: 44,
                color: const Color(0xFF8B5CF6)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.06, 1.06),
              duration: 1600.ms,
              curve: Curves.easeInOut),
          const SizedBox(height: 18),
          Text(unreadMode ? 'All caught up!' : 'No chats yet',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              unreadMode
                  ? 'No unread messages. Nice!'
                  : 'Customer messages will appear here.',
              style: const TextStyle(color: Colors.white54)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 500.ms,
        curve: Curves.easeOutBack);
  }

  // ---------- New-message banner ----------

  Widget _notificationBanner() {
    final b = _banner!;
    final who = b.senderName.isNotEmpty ? b.senderName : b.title;
    return GestureDetector(
      onTap: () => _openThread(b.chatId, b.title),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 2, 20, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [Color(0xFF1E1B3A), Color(0xFF2A1F4D)]),
          border:
              Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 16),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              ),
              child:
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(who,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(b.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      )
          .animate()
          .slideY(begin: -1, end: 0, duration: 300.ms)
          .fadeIn(duration: 300.ms),
    );
  }
}
