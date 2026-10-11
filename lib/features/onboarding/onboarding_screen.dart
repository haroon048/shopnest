import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';

// 3 intro pages - sirf pehli dafa dikhenge.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding/onboarding_1.png',
      'title': 'Shop Everything You Love',
      'desc': 'Fashion, electronics, and more—all in one app.',
    },
    {
      'image': 'assets/images/onboarding/onboarding_2.png',
      'title': 'Secure Payments',
      'desc':
          'Pay securely with Cash on Delivery, cards, JazzCash, or Easypaisa.',
    },
    {
      'image': 'assets/images/onboarding/onboarding_3.png',
      'title': 'Fast Delivery, Live Tracking',
      'desc': 'Track your order live, from checkout to your doorstep.',
    },
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.roleSelect);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('Skip', style: AppTextStyles.caption),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration (glow card me)
                        Container(
                          key: ValueKey('img$i'),
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryViolet.withValues(alpha: 0.25),
                                AppColors.primaryPink.withValues(alpha: 0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryViolet
                                    .withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Image.asset(
                              p['image']!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                            .animate(key: ValueKey('a$i'))
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.92, 0.92),
                              end: const Offset(1, 1),
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),
                        const SizedBox(height: 36),
                        Text(
                          p['title']!,
                          style: AppTextStyles.heading.copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('t$i'))
                            .fadeIn(delay: 150.ms, duration: 450.ms)
                            .slideY(
                              begin: 0.25,
                              end: 0,
                              delay: 150.ms,
                              duration: 450.ms,
                            ),
                        const SizedBox(height: 12),
                        Text(
                          p['desc']!,
                          style: AppTextStyles.caption.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('d$i'))
                            .fadeIn(delay: 280.ms, duration: 450.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _pageController,
              count: _pages.length,
              effect: const WormEffect(
                dotColor: AppColors.surface2,
                activeDotColor: AppColors.primaryViolet,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: PrimaryButton(
                text: isLast ? 'Get Started' : 'Next',
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
