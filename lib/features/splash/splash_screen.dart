import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// Premium glowing splash: neon logo, ping ring, shimmer text, loading dots.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  // 2.5 sec ruko, phir faisla karo: admin home, home, login ya onboarding
  Future<void> _goNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    // Role Firestore se load hota hai — thoda wait karo (max 3 sec)
    if (loggedIn) {
      for (int i = 0; i < 30 && auth.user == null; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
    }
    Navigator.pushReplacementNamed(
      context,
      loggedIn
          ? (auth.isAdmin ? AppRoutes.adminMain : AppRoutes.main)
          : (seen ? AppRoutes.roleSelect : AppRoutes.onboarding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            left: -90,
            child: _glowOrb(AppColors.primaryViolet, 300),
          ),
          Positioned(
            bottom: -110,
            right: -90,
            child: _glowOrb(AppColors.primaryPink, 320),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryViolet.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(0.65, 0.65),
                          end: const Offset(1.2, 1.2),
                          duration: 1800.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 1800.ms),
                    // Logo entrance ke baad halki saans leta hai
                    _glowingLogo()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.045, 1.045),
                          delay: 900.ms,
                          duration: 2000.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 900.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 700.ms),
                const SizedBox(height: 28),
                Text(
                  'ShopNest',
                  style: AppTextStyles.display.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 400.ms,
                      duration: 600.ms,
                    )
                    .shimmer(delay: 1000.ms, duration: 1800.ms),
                const SizedBox(height: 10),
                Text(
                  'Shop Smart, Live Better.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
              ],
            ),
          ),
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        delay: (i * 200).ms,
                        duration: 600.ms,
                      ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ).animate().fadeIn(delay: 900.ms),
          ),
        ],
      ),
    );
  }

  // Glow orb: pulse ke saath halka drift bhi (lamp jaisi zinda motion)
  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.18, 1.18),
          duration: 2600.ms,
          curve: Curves.easeInOut,
        )
        .slide(
          begin: const Offset(-0.06, -0.06),
          end: const Offset(0.06, 0.06),
          duration: 5200.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _glowingLogo() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryViolet.withValues(alpha: 0.55),
            blurRadius: 45,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.35),
            blurRadius: 70,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: Image.asset(
          'assets/images/logo/logo.png',
          width: 88,
          height: 88,
        ),
      ),
    );
  }
}
