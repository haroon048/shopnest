import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/cart_item.dart';
import 'cart_provider.dart';
import '../../core/routes/app_routes.dart';

// Cart tab: items, quantity stepper, swipe-to-delete, bill, promo code.
class CartScreen extends StatefulWidget {
  // Khaali cart me "Shop Now" dabao to Shop tab khul jaye
  final VoidCallback onShopNow;
  const CartScreen({super.key, required this.onShopNow});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Cart', style: AppTextStyles.heading),
      ),
      body: cart.items.isEmpty
          ? _emptyState()
          : Column(
              children: [
                Expanded(child: _itemsList(cart)),
                _billCard(cart),
              ],
            ),
    );
  }

  // Khaali cart wali screen
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/placeholders/empty_cart.png',
              height: 140,
            ),
            const SizedBox(height: 12),
            Text('Your cart is empty', style: AppTextStyles.subHeading),
            const SizedBox(height: 6),
            Text(
              'Browse the shop and add items to your cart.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                text: 'Shop Now',
                onPressed: widget.onShopNow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Items ki list (left swipe karne par delete)
  Widget _itemsList(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (context, i) {
        final item = cart.items[i];
        return Dismissible(
          key: ValueKey(item.productId),
          direction: DismissDirection.endToStart, // sirf left swipe
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.accent),
          ),
          onDismissed: (_) => cart.removeFromCart(item.productId),
          child: _cartTile(cart, item),
        );
      },
    );
  }

  // Ek cart item: image, naam, price, quantity stepper
  Widget _cartTile(CartProvider cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // glass
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.image,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (_, __) => Image.asset(
                'assets/images/placeholders/placeholder_product.png',
                fit: BoxFit.cover,
              ),
              errorWidget: (_, __, ___) => Image.asset(
                'assets/images/placeholders/placeholder_product.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Quantity stepper: - qty +
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: AppColors.textMuted,
                  onPressed: () => cart.updateQty(item.productId, item.qty - 1),
                ),
                Text(
                  '${item.qty}',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: AppColors.primaryViolet,
                  onPressed: () => cart.updateQty(item.productId, item.qty + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Neeche bill card: promo code + hisaab + checkout button
  Widget _billCard(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Promo code lagao ya hatao
            if (cart.promoCode == null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCtrl,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Promo code (WELCOME10)',
                        hintStyle: AppTextStyles.caption,
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final ok = cart.applyPromo(_promoCtrl.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              ok ? 'Promo code applied!' : 'Invalid promo code.'),
                        ),
                      );
                    },
                    child: Text(
                      'Apply',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryViolet,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cart.promoCode} applied',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: cart.removePromo,
                    child: Text(
                      'Remove',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            _billRow('Subtotal', 'Rs ${cart.subtotal.toStringAsFixed(0)}'),
            _billRow(
              'Delivery',
              cart.deliveryFee == 0
                  ? 'FREE'
                  : 'Rs ${cart.deliveryFee.toStringAsFixed(0)}',
              color: cart.deliveryFee == 0 ? AppColors.success : null,
            ),
            if (cart.discount > 0)
              _billRow(
                'Discount',
                '- Rs ${cart.discount.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
            const Divider(color: Colors.white10),
            _billRow(
              'Total',
              'Rs ${cart.total.toStringAsFixed(0)}',
              bold: true,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Checkout',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
            ),
          ],
        ),
      ),
    );
  }

  // Bill ki ek line
  Widget _billRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Text(
            value,
            style:
                (bold ? AppTextStyles.subHeading : AppTextStyles.body).copyWith(
              color:
                  color ?? (bold ? AppColors.primaryPink : AppColors.textWhite),
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}
