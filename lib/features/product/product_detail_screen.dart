import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/rating_stars.dart';
import '../cart/cart_provider.dart';
import '../chat/chat_provider.dart';
import '../wishlist/wishlist_provider.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import 'product_provider.dart';

// Premium product detail screen — gallery, info sheet, fixed bottom bar
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _pageCtrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // Error wala snackbar — asal wajah screen par dikhata hai
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7F1D1D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();
    // Ek hi stream se poori screen (body + bottom bar) banti hai
    return StreamBuilder<DocumentSnapshot>(
      stream: provider.productStream(widget.productId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryViolet,
              ),
            ),
          );
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        if (data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background),
            body: Center(
              child: Text('Product not found.', style: AppTextStyles.body),
            ),
          );
        }
        final p = Product.fromMap(data, snap.data!.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _galleryBar(context, p),
              SliverToBoxAdapter(child: _infoSheet(context, p, provider)),
            ],
          ),
          // Fixed height bottom bar — kabhi poori screen nahi khayegi
          bottomNavigationBar: _bottomBar(context, p),
        );
      },
    );
  }

  // ---------- Image gallery (SliverAppBar) ----------
  Widget _galleryBar(BuildContext context, Product p) {
    final discount = p.oldPrice != null && p.oldPrice! > p.price
        ? ((p.oldPrice! - p.price) / p.oldPrice! * 100).round()
        : 0;
    final count = p.images.isEmpty ? 1 : p.images.length;
    final isFav = context.watch<WishlistProvider>().isFav(p.id);

    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      leadingWidth: 64,
      backgroundColor: AppColors.background,
      leading: _glassBtn(
        icon: Icons.arrow_back,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _glassBtn(
          icon: isFav ? Icons.favorite : Icons.favorite_border,
          color: AppColors.accent,
          onTap: () => context.read<WishlistProvider>().toggleFav(p.id),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Hero(
              tag: 'product-${p.id}',
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: count,
                itemBuilder: (context, i) {
                  if (p.images.isEmpty) return _placeholder();
                  return CachedNetworkImage(
                    imageUrl: p.images[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  );
                },
              ),
            ),
            // Neeche halka gradient taake dots nazar aayen
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            if (discount > 0)
              Positioned(
                top: 100,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFF43F5E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    '-$discount%',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ).animate().scale(delay: 300.ms, duration: 400.ms),
              ),
            // Dots indicator
            if (count > 1)
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    count,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            // Image counter
            if (count > 1)
              Positioned(
                bottom: 14,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_page + 1} / $count',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
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

  // Sheeshe jaisa gol button (back / wishlist)
  Widget _glassBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  // ---------- Neeche wali info sheet ----------
  Widget _infoSheet(BuildContext context, Product p, ProductProvider provider) {
    final out = p.stock <= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chhota handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.name, style: AppTextStyles.heading)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingStars(rating: p.rating, size: 16),
              const SizedBox(width: 8),
              Text(
                '${p.rating} (${p.ratingCount} reviews)',
                style: AppTextStyles.caption,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 14),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.primaryViolet, AppColors.accent],
                ).createShader(b),
                child: Text(
                  'Rs ${p.price.toStringAsFixed(0)}',
                  style: AppTextStyles.display.copyWith(fontSize: 28),
                ),
              ),
              if (p.oldPrice != null) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Rs ${p.oldPrice!.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                      decoration: TextDecoration.lineThrough,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
          const SizedBox(height: 10),
          // Live stock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (out ? AppColors.accent : AppColors.success)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (out ? AppColors.accent : AppColors.success)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: out ? AppColors.accent : AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  out
                      ? 'Out of Stock'
                      : (p.stock < 5
                          ? 'Only ${p.stock} left in stock!'
                          : 'In Stock'),
                  style: AppTextStyles.caption.copyWith(
                    color: out ? AppColors.accent : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 260.ms, duration: 400.ms),
          const SizedBox(height: 20),
          Text('Description', style: AppTextStyles.subHeading),
          const SizedBox(height: 8),
          Text(
            p.description.isEmpty ? 'No description yet.' : p.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          Text('Reviews', style: AppTextStyles.subHeading),
          const SizedBox(height: 10),
          _reviews(provider),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------- Fixed bottom bar (Add to Cart + Chat) ----------
  Widget _bottomBar(BuildContext context, Product p) {
    final out = p.stock <= 0;
    return SafeArea(
      top: false,
      child: Container(
        // Fixed padding — andar ka button fixed height rakhta hai
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat button — fixed 58x58
            SizedBox(
              width: 58,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primaryViolet.withValues(alpha: 0.35),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.primaryViolet,
                  ),
                  onPressed: () => _openChat(p),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart — sirf chaudai me phailta hai, unchai FIXED 58
            Expanded(
              child: SizedBox(
                height: 58,
                child: GestureDetector(
                  onTap: out ? null : () => _addToCart(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: out
                          ? null
                          : const LinearGradient(
                              colors: [
                                AppColors.primaryViolet,
                                AppColors.accent,
                              ],
                            ),
                      color: out ? AppColors.surface2 : null,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: out
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primaryViolet
                                    .withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          out
                              ? Icons.remove_shopping_cart_outlined
                              : Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          out
                              ? 'Out of Stock'
                              : 'Add to Cart • Rs ${p.price.toStringAsFixed(0)}',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chat kholo — error aaye to asal wajah screen par dikhao
  Future<void> _openChat(Product p) async {
    final chatProvider = context.read<ChatProvider>();
    try {
      final chatId = await chatProvider.getOrCreateChat(
        productId: p.id,
        productName: p.name,
        productImage: p.images.isNotEmpty ? p.images.first : '',
        sellerId: p.sellerId,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.chatDetail,
        arguments: chatId,
      );
    } catch (e) {
      _showError('Chat failed: $e');
    }
  }

  // Cart me dalo — error aaye to asal wajah screen par dikhao
  Future<void> _addToCart(Product p) async {
    final cart = context.read<CartProvider>();
    try {
      await cart.addToCart(p);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            '${p.name} was added to your cart.',
          ),
        ),
      );
    } catch (e) {
      _showError('Add to cart failed: $e');
    }
  }

  // Reviews ka live stream
  Widget _reviews(ProductProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: provider.reviewsStream(widget.productId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Text(
            'There are no reviews yet.',
            style: AppTextStyles.caption,
          );
        }
        final reviews = snap.data!.docs
            .map((d) => Review.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        return Column(
          children: reviews
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryViolet,
                                  AppColors.accent,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              r.userName.isNotEmpty
                                  ? r.userName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            r.userName,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          RatingStars(rating: r.rating, size: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.comment,
                        style: AppTextStyles.caption.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
              )
              .toList(),
        );
      },
    );
  }
}
