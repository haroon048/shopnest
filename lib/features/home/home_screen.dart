import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_box.dart';
import 'home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _banners = [
    'assets/images/banners/banner_1.jpg',
    'assets/images/banners/banner_2.jpg',
  ];
  int _bannerIndex = 0;

  // Time ke hisab se greeting (subah/dopahar/shaam)
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ambientOrbs(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => home.refresh(),
              color: AppColors.primaryViolet,
              backgroundColor: AppColors.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    _searchBar(),
                    _bannerCarousel(),
                    const SizedBox(height: 20),
                    _categories(home),
                    const SizedBox(height: 20),
                    _flashDeals(home),
                    const SizedBox(height: 20),
                    _allProducts(home),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Ambient background glows (halke tairte hain) ----------
  Widget _ambientOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryViolet.withValues(alpha: 0.10),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.12, 0.15),
              end: const Offset(-0.12, -0.1),
              duration: 7000.ms,
              curve: Curves.easeInOut),
        ),
        Positioned(
          top: 320,
          left: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.06),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(-0.1, -0.12),
              end: const Offset(0.14, 0.12),
              duration: 8000.ms,
              curve: Curves.easeInOut),
        ),
      ],
    );
  }

  // ---------- Greeting header (gradient title) ----------
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted))
            .animate()
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'What are you looking for?',
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
        ).animate().fadeIn(duration: 450.ms, delay: 80.ms).slideY(
            begin: -0.25, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  // ---------- Floating stadium search bar ----------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 18),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: AppColors.surface.withValues(alpha: 0.7),
            border: Border.all(
                color: AppColors.primaryViolet.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryViolet.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Search products...',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: const Icon(Icons.tune,
                    color: AppColors.textMuted, size: 18),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 450.ms, delay: 120.ms)
          .slideY(
              begin: -0.2, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)
          .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1, 1),
              delay: 120.ms,
              duration: 450.ms),
    );
  }

  // ---------- Banner carousel + animated dots ----------
  Widget _bannerCarousel() {
    return Column(
      children: [
        CarouselSlider(
          items: _banners
              .map(
                (b) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Image.asset(
                          b,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        // Cinematic sheen overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.10),
                                  Colors.transparent,
                                  AppColors.primaryViolet
                                      .withValues(alpha: 0.18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            height: 172,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (i, _) => setState(() => _bannerIndex = i),
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 180.ms).scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == i ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient:
                      _bannerIndex == i ? AppColors.primaryGradient : null,
                  color: _bannerIndex == i
                      ? null
                      : Colors.white.withValues(alpha: 0.2),
                  boxShadow: _bannerIndex == i
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primaryViolet.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
          ],
        ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
      ],
    );
  }

  // ---------- Categories: premium glass tiles (saans leti hui) ----------
  Widget _categories(HomeProvider home) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Categories'),
        const SizedBox(height: 12),
        SizedBox(
          height: 122,
          child: home.loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const Column(
                    children: [
                      ShimmerBox(height: 68, width: 68, radius: 20),
                      SizedBox(height: 8),
                      ShimmerBox(height: 10, width: 56, radius: 5),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: home.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = home.categories[i];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.shop,
                        arguments: {'categoryId': c.id},
                      ),
                      child: Container(
                        width: 94,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: AppColors.surface.withValues(alpha: 0.6),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Tile image halki saans leti hai (lamp jaisi motion)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                c.imageUrl,
                                width: 62,
                                height: 62,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/placeholders/placeholder_product.png',
                                  width: 62,
                                  height: 62,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                                .animate(
                                    onPlay: (ctrl) =>
                                        ctrl.repeat(reverse: true))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.06, 1.06),
                                    duration: (1500 + (i % 4) * 180).ms,
                                    curve: Curves.easeInOut),
                            const SizedBox(height: 8),
                            Text(
                              c.name,
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (i * 70).ms, duration: 400.ms)
                        .slideY(
                            begin: 0.35,
                            end: 0,
                            delay: (i * 70).ms,
                            duration: 450.ms,
                            curve: Curves.easeOutBack)
                        .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            delay: (i * 70).ms,
                            duration: 450.ms);
                  },
                ),
        ),
      ],
    );
  }

  // ---------- Flash deals: LIVE badge + box countdown ----------
  Widget _flashDeals(HomeProvider home) {
    if (home.loading || home.flashDeals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Flash Deals'),
            const SizedBox(width: 10),
            _liveBadge(),
            const Spacer(),
            if (home.flashDeals.first.dealEndsAt != null)
              _DealTimer(endsAt: home.flashDeals.first.dealEndsAt!),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 252,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: home.flashDeals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 170,
              child: ProductCard(product: home.flashDeals[i]),
            )
                .animate()
                .fadeIn(delay: (i * 80).ms, duration: 400.ms)
                .slideX(
                    begin: 0.35,
                    end: 0,
                    delay: (i * 80).ms,
                    duration: 450.ms,
                    curve: Curves.easeOutCubic)
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    delay: (i * 80).ms,
                    duration: 450.ms),
          ),
        ),
      ],
    );
  }

  // Pulsing LIVE badge.
  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
            colors: [Color(0xFFF43F5E), Color(0xFFEC4899)]),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkDot(),
          SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.08, 1.08),
        duration: 900.ms,
        curve: Curves.easeInOut);
  }

  // ---------- All products grid ----------
  Widget _allProducts(HomeProvider home) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('All Products'),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
              child: Text('See all →',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryViolet,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (home.loading)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (_, __) => const ShimmerBox(
                height: 220, width: double.infinity, radius: 20),
          )
        else if (home.products.isEmpty)
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/placeholders/placeholder_product.png',
                  height: 120,
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1600.ms,
                    curve: Curves.easeInOut),
                const SizedBox(height: 8),
                Text('No products found.', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  'Add products in the Firebase Console (see SAMPLE_DATA.md).',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ).animate().fadeIn(duration: 500.ms),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: home.products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, i) => ProductCard(product: home.products[i])
                .animate()
                .fadeIn(delay: ((i % 6) * 70).ms, duration: 450.ms)
                .slideY(
                    begin: 0.2,
                    end: 0,
                    delay: ((i % 6) * 70).ms,
                    duration: 450.ms,
                    curve: Curves.easeOutBack)
                .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    delay: ((i % 6) * 70).ms,
                    duration: 450.ms),
          ),
      ],
    );
  }

  // ---------- Section heading (glowing gradient bar) ----------
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 22,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryViolet.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTextStyles.subHeading
                .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.25, end: 0, duration: 400.ms);
  }
}

// Blinking dot inside the LIVE badge.
class _BlinkDot extends StatelessWidget {
  const _BlinkDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 500.ms)
        .fadeOut(duration: 500.ms);
  }
}

// Flash deal countdown — segmented boxes (har second update).
class _DealTimer extends StatefulWidget {
  final DateTime endsAt;
  const _DealTimer({required this.endsAt});

  @override
  State<_DealTimer> createState() => _DealTimerState();
}

class _DealTimerState extends State<_DealTimer> {
  late Timer _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final diff = widget.endsAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _left = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(_two(_left.inHours)),
        _colon(),
        _box(_two(_left.inMinutes % 60)),
        _colon(),
        _box(_two(_left.inSeconds % 60)),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _colon() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Text(':',
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
      );

  Widget _box(String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(v,
          style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}
