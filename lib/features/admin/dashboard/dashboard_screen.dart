import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../account/admin_account_screen.dart';
import '../../auth/auth_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dashboard_provider.dart';

// Admin dashboard: live stats + taaza orders
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ambientOrbs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryViolet.withValues(alpha: 0.85),
                          AppColors.primaryPink.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryViolet.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Admin Panel',
                                  style: AppTextStyles.heading.copyWith(
                                      color: Colors.white, fontSize: 22)),
                            ),
                            IconButton(
                              tooltip: 'Account',
                              icon: const Icon(
                                Icons.account_circle_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminAccountScreen(),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _logout(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ShopNest control room — everything live.',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: -0.2, end: 0, duration: 450.ms),
                  const SizedBox(height: 16),

                  // Stats grid (live + count-up)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _statCard(
                        stream: dash.ordersCount(),
                        label: 'Total Orders',
                        icon: Icons.receipt_long_outlined,
                        format: (v) => '$v',
                        index: 0,
                      ),
                      _statCard(
                        stream: dash.totalRevenue(),
                        label: 'Revenue',
                        icon: Icons.payments_outlined,
                        format: (v) => 'Rs ${v.toStringAsFixed(0)}',
                        index: 1,
                      ),
                      _statCard(
                        stream: dash.productsCount(),
                        label: 'Products',
                        icon: Icons.inventory_2_outlined,
                        format: (v) => '$v',
                        index: 2,
                      ),
                      _statCard(
                        stream: dash.usersCount(),
                        label: 'Users',
                        icon: Icons.people_outline,
                        format: (v) => '$v',
                        index: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Taaza orders (live)
                  Text('Live Orders', style: AppTextStyles.subHeading)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: dash.recentOrders(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return Center(
                          child:
                              Text('Loading...', style: AppTextStyles.caption),
                        );
                      }
                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return Text('There are no orders yet.',
                            style: AppTextStyles.caption);
                      }
                      return Column(
                        children: List.generate(
                          docs.length,
                          (i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            return _orderRow(
                              id: docs[i].id,
                              status: '${d['status'] ?? 'pending'}',
                              total: (d['total'] as num?)?.toDouble() ?? 0,
                              index: i,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Halke tairte hue glows ----------
  Widget _ambientOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryViolet.withValues(alpha: 0.10),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.12, 0.12),
              end: const Offset(-0.12, -0.1),
              duration: 7000.ms,
              curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 60,
          left: -70,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.06),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(-0.1, -0.1),
              end: const Offset(0.12, 0.12),
              duration: 8000.ms,
              curve: Curves.easeInOut),
        ),
      ],
    );
  }

// Logout -> wapas role select screen par
  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelect,
        (_) => false,
      );
    }
  }

  // Live stat card (staggered springy entrance + count-up number)
  Widget _statCard({
    required Stream<num> stream,
    required String label,
    required IconData icon,
    required String Function(num) format,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: StreamBuilder<num>(
        stream: stream,
        builder: (context, snap) {
          final value = snap.data ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: (1400 + index * 150).ms,
                  curve: Curves.easeInOut),
              const SizedBox(height: 10),
              // Number 0 se count-up hokar aata hai
              _CountUpText(value: value, format: format),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          );
        },
      ),
    )
        .animate()
        .fadeIn(delay: (index * 90).ms, duration: 400.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          delay: (index * 90).ms,
          duration: 400.ms,
        )
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          delay: (index * 90).ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  // Order ki aik line (status chip ke saath)
  Widget _orderRow({
    required String id,
    required String status,
    required double total,
    required int index,
  }) {
    final shortId = id.length > 6 ? id.substring(0, 6) : id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#$shortId...',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Rs ${total.toStringAsFixed(0)}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          _statusChip(status),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 350.ms)
        .slideX(
          begin: 0.2,
          end: 0,
          delay: (index * 80).ms,
          duration: 350.ms,
        )
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          delay: (index * 80).ms,
          duration: 350.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'shipped':
        color = AppColors.primaryViolet;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange; // pending
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// Number 0 se smoothly count-up hokar target tak jata hai.
// Stream se nayi value aaye to purani value se nayi tak animate hota hai.
class _CountUpText extends StatefulWidget {
  final num value;
  final String Function(num) format;
  const _CountUpText({required this.value, required this.format});

  @override
  State<_CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<_CountUpText> {
  num _from = 0;

  @override
  void didUpdateWidget(_CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value; // purani value se nayi value tak gino
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<num>(
      tween: Tween<num>(begin: _from, end: widget.value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        widget.format(v),
        style: AppTextStyles.subHeading
            .copyWith(color: AppColors.primaryPink, fontSize: 18),
      ),
    );
  }
}
