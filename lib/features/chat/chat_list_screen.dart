import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message.dart';
import 'chat_provider.dart';

/// Meri saari chats — premium messenger style,
/// unread badges, new-message banner.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  StreamSubscription<ChatNotificationEvent>? _notifSub;
  ChatNotificationEvent? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chat = context.read<ChatProvider>();
    chat.startNotifications(myUid);
    _notifSub = chat.notificationsStream.listen((event) {
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
    super.dispose();
  }

  void _openThread(String chatId) {
    setState(() => _banner = null);
    Navigator.pushNamed(
      context,
      AppRoutes.chatDetail,
      arguments: chatId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final chat = context.read<ChatProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (_banner != null) _notificationBanner(),
            _searchBar(),
            Expanded(
              child: StreamBuilder<List<ChatThread>>(
                stream: chat.chatsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryViolet),
                    );
                  }
                  var list = snap.data ?? [];
                  if (_query.isNotEmpty) {
                    list = list
                        .where((t) => '${t.productName} ${t.lastMessage}'
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                        .toList();
                  }
                  if (list.isEmpty) {
                    return _emptyState();
                  }
                  return StreamBuilder<Map<String, int>>(
                    stream: chat.unreadMapStream(myUid),
                    builder: (context, unreadSnap) {
                      final unread = unreadSnap.data ?? {};
                      return ListView.separated(
                        padding: const EdgeInsets.only(top: 6, bottom: 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.only(left: 96),
                          child: Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        itemBuilder: (context, i) =>
                            _row(list[i], unread[list[i].id] ?? 0, i),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Text(
              'Chats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.4, end: 0, duration: 400.ms);
  }

  // ---------- Search ----------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search chats',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primaryViolet),
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
        .slideY(begin: 0.3, end: 0, duration: 400.ms);
  }

  // ---------- Chat row ----------
  Widget _row(ChatThread t, int unread, int index) {
    return GestureDetector(
      onTap: () => _openThread(t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            // Avatar (gradient ring)
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: unread > 0
                        ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                        : [
                            Colors.white.withValues(alpha: 0.20),
                            Colors.white.withValues(alpha: 0.08)
                          ]),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: t.productImage,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/placeholders/placeholder_product.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              unread > 0 ? FontWeight.bold : FontWeight.w600)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            t.lastMessage.isEmpty
                                ? 'Start a conversation'
                                : t.lastMessage,
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
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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

  /// Pulsing unread badge — cart badge jaisa.
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

  // ---------- Empty state ----------
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.primaryViolet.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.15),
                ]),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.25),
                      blurRadius: 24),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 44, color: AppColors.primaryViolet),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1600.ms,
                curve: Curves.easeInOut),
            const SizedBox(height: 18),
            const Text('No conversations yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Open a product and tap the chat button to talk to the seller.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  // ---------- New-message banner ----------
  Widget _notificationBanner() {
    final b = _banner!;
    final who = b.senderName.isNotEmpty ? b.senderName : b.title;
    return GestureDetector(
      onTap: () => _openThread(b.chatId),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 2, 20, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              colors: [Color(0xFF1E1B3A), Color(0xFF2A1F4D)]),
          border:
              Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryViolet.withValues(alpha: 0.3),
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
