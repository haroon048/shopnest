import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_nav_icon.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_provider.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';

// Main app shell with five tabs and a floating frosted-glass navigation bar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // Chat tab ke badge ke liye: saari chats ka total unread count
  int _unreadTotal = 0;
  String? _unreadUid;
  StreamSubscription? _unreadSub;

  late final List<Widget> _tabs = [
    const HomeScreen(),
    const ShopScreen(),
    CartScreen(onShopNow: () => setState(() => _index = 1)),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Shop',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: 'Cart',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Login/logout ya user change par unread stream dobara lagao
    final uid = context.watch<AuthProvider>().user?.uid;
    if (uid != _unreadUid) {
      _unreadUid = uid;
      _unreadSub?.cancel();
      _unreadSub = null;
      _unreadTotal = 0;
      if (uid != null) {
        _unreadSub =
            context.read<ChatProvider>().unreadMapStream(uid).listen((map) {
          var total = 0;
          for (final v in (map as Map).values) {
            total += (v as num).toInt();
          }
          if (mounted && total != _unreadTotal) {
            setState(() => _unreadTotal = total);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  // Chhota gol count badge (cart + chat dono ke liye).
  // Count badle to pop animation ke saath zahir hota hai.
  Widget _countBadge(String text, String tag) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate(key: ValueKey('nav_badge_${tag}_$text')).scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final active = i == _index;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedNavIcon(
                                active: active,
                                icon: item.icon,
                                activeIcon: item.activeIcon,
                              ),
                              // Cart badge (jaise pehle tha)
                              if (i == 2 && cartCount > 0)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: _countBadge('$cartCount', 'cart'),
                                ),
                              // Chat badge: naya message aaye to unread count
                              if (i == 3 && _unreadTotal > 0)
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: _countBadge('$_unreadTotal', 'chat'),
                                ),
                            ],
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
