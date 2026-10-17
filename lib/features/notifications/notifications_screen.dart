import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/app_notification.dart';
import 'notification_provider.dart';

// Notification center: saari notifications ek jagah.
// Tap -> us chat / order par jao. Swipe -> delete. Sab parha hua mark karo.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: AppTextStyles.subHeading),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => provider.markAllAsRead(),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.primaryPink, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: provider.notificationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) return _emptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _tile(context, provider, list[i]),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationProvider>().markAsRead(n.id);
    if (n.type == 'chat' && n.refId.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: n.refId);
    } else if (n.type == 'order' && n.refId.isNotEmpty) {
      Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: n.refId);
    }
  }

  Widget _tile(
      BuildContext context, NotificationProvider provider, AppNotification n) {
    final icon = n.type == 'chat'
        ? Icons.chat_bubble_outline
        : n.type == 'order'
            ? Icons.receipt_long_outlined
            : Icons.notifications_outlined;
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.red.withValues(alpha: 0.25),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => provider.deleteNotification(n.id),
      child: GestureDetector(
        onTap: () => _open(context, n),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: n.isRead
                ? AppColors.surface.withValues(alpha: 0.5)
                : AppColors.surface.withValues(alpha: 0.85),
            border: Border.all(
              color: n.isRead
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.primaryViolet.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(n.createdAt),
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: AppTextStyles.body.copyWith(fontSize: 13.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!n.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.notifications_none,
                size: 44, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text('No notifications yet', style: AppTextStyles.subHeading),
          const SizedBox(height: 6),
          Text(
            'New messages and order updates will appear here.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
