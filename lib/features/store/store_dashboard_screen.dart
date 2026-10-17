import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'create_store_screen.dart';
import 'store_provider.dart';

// Mere store ka dashboard — apni dukaan ka board.
// Animated gradient header + stylish logo/naam + count-up stats.
class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _breathe;
  late final AnimationController _gradient;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Entrance: saare sections ek ke baad ek aayenge
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    // Logo ki saans (halki si scale animation)
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    // Header gradient ka slow shift
    _gradient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = context.read<StoreProvider>();
      await sp.loadMyStore();
      await sp.loadMyStoreStats();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _breathe.dispose();
    _gradient.dispose();
    super.dispose();
  }

  Future<void> _openCreateStore() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoreScreen()),
    );
    if (created == true && mounted) {
      setState(() => _ready = false);
      final sp = context.read<StoreProvider>();
      await sp.loadMyStore();
      await sp.loadMyStoreStats();
      if (mounted) setState(() => _ready = true);
    }
  }

  // Route na mile to crash ke bajaye message dikhao
  void _go(String route, String label) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label connects in the next step.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Consumer<StoreProvider>(
              builder: (context, sp, _) {
                final store = sp.myStore;
                if (store == null) return _noStoreState();
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _header(store.name, store.category, store.rating,
                          store.ratingCount, store.logoUrl),
                      const SizedBox(height: 20),
                      _animatedSection(
                        start: 0.15,
                        child: _statsRow(sp),
                      ),
                      const SizedBox(height: 22),
                      _animatedSection(
                        start: 0.35,
                        child: _quickActions(),
                      ),
                      const SizedBox(height: 22),
                      _animatedSection(
                        start: 0.55,
                        child: _recentOrders(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Store abhi nahi bana to pehle banane ko kaho
  Widget _noStoreState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child:
                  const Icon(Icons.storefront, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text('No store yet', style: AppTextStyles.subHeading),
            const SizedBox(height: 8),
            Text(
              'Create your store to start selling.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _openCreateStore,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.primaryGradient,
                ),
                child: const Text(
                  'Create My Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- BRANDED HEADER ----------
  Widget _header(String name, String category, double rating, int ratingCount,
      String logoUrl) {
    return AnimatedBuilder(
      animation: _gradient,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            gradient: LinearGradient(
              begin: Alignment(-1 + _gradient.value, -1),
              end: Alignment(1 - _gradient.value, 1),
              colors: [
                AppColors.primaryViolet,
                AppColors.primaryPink,
                AppColors.primaryViolet,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryViolet.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'My Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 10),
              // Logo (saans leti hui)
              AnimatedBuilder(
                animation: _breathe,
                builder: (context, _) {
                  return Transform.scale(
                    scale: 1 + 0.05 * _breathe.value,
                    child: Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      // Logo image ho to image, warna naam ka pehla letter
                      child: logoUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                logoUrl,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _headerInitial(name),
                              ),
                            )
                          : _headerInitial(name),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              // Store ka naam — bara aur stylish
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chip(Icons.category_outlined, category),
                  const SizedBox(width: 8),
                  _chip(Icons.verified, 'Active Store'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 17),
                  const SizedBox(width: 4),
                  Text(
                    '${rating.toStringAsFixed(1)}  •  $ratingCount reviews',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Header logo me naam ka pehla letter (jab logo image na ho)
  Widget _headerInitial(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'S',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 52,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- STATS (count-up) ----------
  Widget _statsRow(StoreProvider sp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Revenue',
              child: _countUp(sp.myRevenue, isMoney: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              child: _countUp(sp.myOrders.toDouble()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              child: _countUp(sp.myProducts.toDouble()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          child,
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // 0 se number tak count-up animation
  Widget _countUp(double value, {bool isMoney = false}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOut,
      builder: (context, v, _) {
        final text = isMoney ? 'Rs ${v.toInt()}' : '${v.toInt()}';
        return Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }

  // ---------- QUICK ACTIONS ----------
  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Store', style: AppTextStyles.subHeading),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _actionTile(
                icon: Icons.add_box_outlined,
                title: 'Add Product',
                sub: 'List a new item',
                onTap: () => _go('/admin-add-product', 'Add Product'),
              ),
              _actionTile(
                icon: Icons.inventory_2_outlined,
                title: 'My Products',
                sub: 'Edit or delete',
                onTap: () => _go('/admin-products', 'My Products'),
              ),
              _actionTile(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                sub: 'Track & update',
                onTap: () => _go('/admin-orders', 'Orders'),
              ),
              _actionTile(
                icon: Icons.chat_bubble_outline,
                title: 'Chats',
                sub: 'Talk to buyers',
                onTap: () => _go('/admin-chats', 'Chats'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface.withValues(alpha: 0.75),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.primaryGradient,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(sub, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  // ---------- RECENT ORDERS ----------
  Widget _recentOrders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: AppTextStyles.subHeading),
              GestureDetector(
                onTap: () => _go('/admin-orders', 'Orders'),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surface.withValues(alpha: 0.75),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 38,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 10),
                Text(
                  'No orders yet',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Orders from your store will appear here.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ek section ko fade + slide ke saath dikhao
  Widget _animatedSection({required double start, required Widget child}) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }
}
