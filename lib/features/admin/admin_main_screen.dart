import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'orders/admin_orders_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_nav_icon.dart';
import '../auth/auth_provider.dart';
import 'categories/admin_categories_screen.dart';
import 'chats/admin_chats_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/admin_products_screen.dart';

// Admin ka main shell: Dashboard, Products, Orders, Chats
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _index = 0;

  final List<Widget> _tabs = const [
    DashboardScreen(),
    AdminProductsScreen(),
    AdminCategoriesScreen(),
    AdminOrdersScreen(),
    AdminChatsScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard'),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Products'),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      label: 'Categories',
    ),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: 'Orders'),
    _NavItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'Chats'),
  ];

  @override
  Widget build(BuildContext context) {
    // Safety: customer yahan aa jaye to wapas bhejo
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Access denied.', style: AppTextStyles.subHeading),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.75),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final active = i == _index;
                  return GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.primaryGradient : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedNavIcon(
                            active: active,
                            icon: item.icon,
                            activeIcon: item.activeIcon,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color:
                                  active ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
