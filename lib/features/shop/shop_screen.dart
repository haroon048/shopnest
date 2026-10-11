import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/product.dart';
import '../home/home_provider.dart';
import '../wishlist/wishlist_provider.dart';

// Premium shop: glass luxe cards + image category chips + sort bottom-sheet.
// Products HomeProvider se aate hain (dobara Firestore read nahi hoti).
class ShopScreen extends StatefulWidget {
  final String? initialCategoryId; // home se category tap karke aao to
  const ShopScreen({super.key, this.initialCategoryId});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _catId;
  String _sort = 'all'; // all, low, high, rating
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategoryId;
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Product> _filtered(List<Product> all) {
    var list = all.toList();
    if (_catId != null) {
      list = list.where((p) => p.categoryId == _catId).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (_sort == 'low') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sort == 'high') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sort == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  String get _sortLabel {
    switch (_sort) {
      case 'low':
        return 'Price: Low to High';
      case 'high':
        return 'Price: High to Low';
      case 'rating':
        return 'Top Rated';
      default:
        return 'Default';
    }
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onPick: (v) => setState(() => _sort = v),
      ),
    );
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _catId = null;
      _sort = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final list = _filtered(home.products);
    final hasFilters = _query.isNotEmpty || _catId != null || _sort != 'all';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ambientOrbs(),
          SafeArea(
            child: Column(
              children: [
                _header(list.length),
                _searchBar(),
                _categoryChips(home),
                _toolbar(list.length, hasFilters),
                Expanded(
                  child: list.isEmpty
                      ? _emptyState(hasFilters)
                      : _grid(list, '$_catId|$_sort'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Ambient glows (lamp ki tarah halke tairte hain) ----------
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
          bottom: 100,
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

  // ---------- Gradient header + wishlist button ----------
  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'Shop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('$count products',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.wishlist),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withValues(alpha: 0.7),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_border,
                  color: AppColors.accent, size: 22),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1800.ms,
                curve: Curves.easeInOut),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.4, end: 0, duration: 400.ms);
  }

  // ---------- Floating stadium search (live filter) ----------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: AppColors.surface.withValues(alpha: 0.7),
          border: Border.all(
              color: _searchFocused
                  ? AppColors.primaryViolet.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08)),
          boxShadow: _searchFocused
              ? [
                  BoxShadow(
                    color: AppColors.primaryViolet.withValues(alpha: 0.25),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primaryViolet),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppColors.textMuted, size: 20),
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

  // ---------- Category image chips (tasveer wale, gradient ring) ----------
  Widget _categoryChips(HomeProvider home) {
    final cats = home.categories;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == 0) return _chip('All', null, null, 0);
          final c = cats[i - 1];
          return _chip(c.name, c.id, c.imageUrl, i);
        },
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms);
  }

  Widget _chip(String label, String? id, String? imageUrl, int index) {
    final selected = _catId == id;
    return GestureDetector(
      onTap: () => setState(() => _catId = id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: selected ? 68 : 60,
            height: selected ? 68 : 60,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? AppColors.primaryGradient : null,
              border: selected
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.55),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.category_outlined,
                            color: AppColors.primaryViolet),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.grid_view_rounded,
                          color: AppColors.primaryViolet),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 74,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (160 + index * 60).ms, duration: 350.ms).slideY(
        begin: 0.4,
        end: 0,
        delay: (160 + index * 60).ms,
        duration: 400.ms,
        curve: Curves.easeOutBack);
  }

  // ---------- Count + sort button + clear ----------
  Widget _toolbar(int count, bool hasFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Text('$count ${count == 1 ? 'product' : 'products'}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearFilters,
              child: Text('Clear',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _openSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface.withValues(alpha: 0.7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 16, color: AppColors.primaryViolet),
                  const SizedBox(width: 6),
                  Text(_sortLabel,
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms, duration: 400.ms);
  }

  // ---------- Product grid: glass luxe cards (filter par dobara animate) ----------
  Widget _grid(List<Product> list, String animKey) {
    return GridView.builder(
      key: ValueKey(animKey), // category/sort badle to cards dobara animate hon
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) => _GlassProductCard(product: list[i])
          .animate()
          .fadeIn(delay: ((i % 6) * 60).ms, duration: 450.ms)
          .slideY(
              begin: 0.2,
              end: 0,
              delay: ((i % 6) * 60).ms,
              duration: 450.ms,
              curve: Curves.easeOutBack)
          .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              delay: ((i % 6) * 60).ms,
              duration: 450.ms),
    );
  }

  // ---------- Premium empty state ----------
  Widget _emptyState(bool hasFilters) {
    return Center(
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
                AppColors.accent.withValues(alpha: 0.12),
              ]),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryViolet.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 44, color: AppColors.primaryViolet),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.06, 1.06),
              duration: 1600.ms,
              curve: Curves.easeInOut),
          const SizedBox(height: 18),
          const Text('No products found',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Try a different search or filter.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Text('Clear filters',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 500.ms,
        curve: Curves.easeOutBack);
  }
}

// ============================================================
// PREMIUM GLASS PRODUCT CARD — sheeshe jaisa luxurious design
// Floating price pill, glass wishlist heart, pulsing discount badge
// ============================================================
class _GlassProductCard extends StatefulWidget {
  final Product product;
  const _GlassProductCard({required this.product});

  @override
  State<_GlassProductCard> createState() => _GlassProductCardState();
}

class _GlassProductCardState extends State<_GlassProductCard> {
  bool _pressed = false;

  bool _isWishlisted(WishlistProvider w, String id) {
    try {
      return (w as dynamic).isWishlisted(id) ?? false;
    } catch (_) {
      return false;
    }
  }

  void _toggleWishlist(WishlistProvider w, Product p) {
    try {
      (w as dynamic).toggleWishlist(p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final wishlist = context.watch<WishlistProvider>();
    final wishlisted = _isWishlisted(wishlist, p.id);

    final hasDiscount = p.oldPrice != null && p.oldPrice! > p.price;
    final discountPct = hasDiscount
        ? '-${(((p.oldPrice! - p.price) / p.oldPrice!) * 100).round()}%'
        : null;
    final image = p.images.isNotEmpty ? p.images.first : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: p.id,
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Sheesha: halki translucent gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.primaryViolet.withValues(alpha: 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Image + floating pills ----
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: image != null
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                        ),
                        // Neeche cinematic fade
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Discount badge (dhadakta hua)
                        if (discountPct != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFEC4899),
                                  Color(0xFFF43F5E)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(discountPct,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.07, 1.07),
                                    duration: 1100.ms,
                                    curve: Curves.easeInOut),
                          ),
                        // Wishlist heart (sheeshe ka, kaam karta hai)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _toggleWishlist(wishlist, p),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: wishlisted
                                    ? AppColors.primaryPink
                                        .withValues(alpha: 0.85)
                                    : Colors.black.withValues(alpha: 0.35),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.30)),
                                boxShadow: wishlisted
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryPink
                                              .withValues(alpha: 0.55),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                wishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(wishlisted),
                                color: Colors.white,
                                size: 18,
                              ).animate(key: ValueKey('pop-$wishlisted')).scale(
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1, 1),
                                  duration: 250.ms,
                                  curve: Curves.easeOutBack),
                            ),
                          ),
                        ),
                        // Tairti hui price pill
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.black.withValues(alpha: 0.55),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => AppColors
                                  .primaryGradient
                                  .createShader(bounds),
                              child: Text(
                                'Rs ${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        // Rating pill
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withValues(alpha: 0.55),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    size: 13, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${p.rating}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ---- Info ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subHeading.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasDiscount)
                              Text(
                                'Rs ${p.oldPrice!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough),
                              ),
                            if (hasDiscount) const SizedBox(width: 6),
                            Text('${p.ratingCount} reviews',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Sheeshe ki chamak: upar halki highlight line
              Positioned(
                top: 0,
                left: 28,
                right: 28,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.45),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Image.asset(
      'assets/images/placeholders/placeholder_product.png',
      fit: BoxFit.cover,
    );
  }
}

// ---------- Premium sort bottom-sheet ----------
class _SortSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;
  const _SortSheet({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('all', 'Default', Icons.list_rounded),
      ('low', 'Price: Low to High', Icons.arrow_upward_rounded),
      ('high', 'Price: High to Low', Icons.arrow_downward_rounded),
      ('rating', 'Top Rated', Icons.star_rounded),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Sort by',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (int i = 0; i < options.length; i++)
            _option(context, options[i], i),
        ],
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 350.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 250.ms);
  }

  Widget _option(BuildContext context, (String, String, IconData) opt, int i) {
    final selected = current == opt.$1;
    return GestureDetector(
      onTap: () {
        onPick(opt.$1);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.08)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryViolet.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(opt.$3,
                color: selected ? Colors.white : AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(opt.$2,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500)),
            ),
            if (selected) const Icon(Icons.check_rounded, color: Colors.white),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (i * 60).ms, duration: 300.ms)
        .slideX(begin: 0.2, end: 0, delay: (i * 60).ms, duration: 300.ms);
  }
}
