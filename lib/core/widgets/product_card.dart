import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ═══════════════════════════════════════════════════════════
// ⚠️ APNE PROJECT SE MATCH KARO — agar error aaye to ye theek karo:
// 1. Product model ka import + class naam (neeche "Product" likha hai)
// 2. Fields: id, name, price, oldPrice, images (List), rating, ratingCount
// 3. WishlistProvider methods: isWishlisted(id) -> bool,
//    toggleWishlist(product)
// 4. Detail route: AppRoutes.productDetail, arguments: product.id
// ═══════════════════════════════════════════════════════════
import '../../models/product.dart'; // ← APNA PATH LAGAO
import '../../features/wishlist/wishlist_provider.dart'; // ← APNA PATH LAGAO

/// Premium product card — press-to-shrink, discount badge,
/// animated wishlist heart, gradient price.
class ProductCard extends StatefulWidget {
  final Product product;
  final double? width;
  const ProductCard({super.key, required this.product, this.width});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  bool _isWishlisted(WishlistProvider provider, String productId) {
    try {
      return (provider as dynamic).isWishlisted(productId) ?? false;
    } catch (_) {
      return false;
    }
  }

  void _toggleWishlist(WishlistProvider provider, Product product) {
    try {
      (provider as dynamic).toggleWishlist(product);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final wishlistProvider = context.watch<WishlistProvider>();
    final wishlisted = _isWishlisted(wishlistProvider, p.id);

    final hasDiscount = p.oldPrice != null && p.oldPrice! > p.price;
    final discountPct = hasDiscount
        ? '-${(((p.oldPrice! - p.price) / p.oldPrice!) * 100).round()}%'
        : null;
    final image = (p.images.isNotEmpty) ? p.images.first : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail, // ← APNA ROUTE LAGAO
        arguments: p.id,
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surface,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Image ----
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 1.02,
                      child: image != null
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  // Cinematic bottom fade
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Discount badge
                  if (discountPct != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF43F5E)]),
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
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.07, 1.07),
                          duration: 1100.ms,
                          curve: Curves.easeInOut),
                    ),
                  // Wishlist heart (glass)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      // NOTE: apne provider ka method lagao
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Icon(
                          wishlisted ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(wishlisted),
                          color: wishlisted
                              ? const Color(0xFFEC4899)
                              : Colors.white,
                          size: 18,
                        ).animate(key: ValueKey('pop-$wishlisted')).scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 250.ms,
                            curve: Curves.easeOutBack),
                      ),
                    ),
                  ),
                ],
              ),
              // ---- Info ----
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subHeading
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${p.rating}', style: AppTextStyles.caption),
                        Text(' (${p.ratingCount})',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: Text(
                            'Rs ${p.price}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Rs ${p.oldPrice}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                  ],
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
