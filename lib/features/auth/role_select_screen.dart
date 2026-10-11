import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'login_screen.dart';

// Splash ke baad: Admin ya Customer? (boss demo ke liye perfect)
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Glowing logo
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                  child: Image.asset(
                    'assets/images/logo/logo.png',
                    width: 52,
                    height: 52,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: 20),
              Text('Welcome to ShopNest',
                      style: AppTextStyles.heading.copyWith(fontSize: 24))
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 450.ms)
                  .slideY(begin: -0.2, end: 0, duration: 450.ms),
              const SizedBox(height: 8),
              Text('Continue as...',
                      style: AppTextStyles.caption.copyWith(fontSize: 14))
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 450.ms),
              const SizedBox(height: 36),
              _roleCard(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Admin',
                desc: 'Manage products, orders, and chats',
                colors: const [AppColors.primaryViolet, Color(0xFF6D28D9)],
                role: 'admin',
                index: 0,
              ),
              const SizedBox(height: 16),
              _roleCard(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'Customer',
                desc: 'Shop, place orders, and track deliveries',
                colors: const [AppColors.primaryPink, Color(0xFFDB2777)],
                role: 'customer',
                index: 1,
              ),
              const Spacer(),
              Text(
                'Sign in with the account for your role',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required List<Color> colors,
    required String role,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        if (role == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(
                role: 'admin',
                hideSignUp: true,
              ),
            ),
          );
          return;
        }
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
          arguments: role,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.subHeading
                          .copyWith(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (300 + index * 130).ms, duration: 450.ms).slideX(
          begin: 0.3,
          end: 0,
          delay: (300 + index * 130).ms,
          duration: 450.ms,
        );
  }
}
