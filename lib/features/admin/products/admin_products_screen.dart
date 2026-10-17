import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shopnest/features/store/create_store_screen.dart';
import 'package:shopnest/features/store/store_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/product.dart';

import 'admin_product_provider.dart';
import 'product_form_screen.dart';

// Admin: apne store ke products ki list + add/edit/delete
// Sirf apne storeId wale products dikhte hain (purane bina-storeId
// wale bhi dikhte hain taake migration se pehle kuch gayab na ho).
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _loadingStore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StoreProvider>().loadMyStore();
      if (mounted) setState(() => _loadingStore = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final admin = context.watch<AdminProductProvider>();

    if (_loadingStore) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryViolet),
        ),
      );
    }

    final myStore = storeProvider.myStore;
    if (myStore == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Products',
              style: AppTextStyles.heading.copyWith(fontSize: 20)),
        ),
        body: _noStoreState(),
      );
    }

    final myStoreId = myStore.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Products',
                style: AppTextStyles.heading.copyWith(fontSize: 20))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.2, end: 0, duration: 400.ms),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 1600.ms,
                  curve: Curves.easeInOut),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _ambientOrbs(),
          StreamBuilder<List<Product>>(
            stream: admin.productsStream(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryViolet),
                );
              }
              // Sirf mere store ke products (purane bina-storeId wale bhi,
              // taake migration se pehle kuch gayab na ho).
              final products = snap.data!
                  .where((p) => p.storeId == myStoreId || p.storeId.isEmpty)
                  .toList();
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppColors.primaryViolet.withValues(alpha: 0.25),
                            AppColors.accent.withValues(alpha: 0.12),
                          ]),
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 38, color: AppColors.primaryViolet),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.06, 1.06),
                          duration: 1600.ms,
                          curve: Curves.easeInOut),
                      const SizedBox(height: 14),
                      Text('No products yet.\nTap + to add your first product.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption),
                    ],
                  ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _productRow(context, products[i])
                    .animate()
                    .fadeIn(delay: (i * 60).ms, duration: 350.ms)
                    .slideX(
                      begin: 0.25,
                      end: 0,
                      delay: (i * 60).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: (i * 60).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Store abhi nahi bana to pehle banane ko kaho
  Widget _noStoreState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child:
                  const Icon(Icons.storefront, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('No store yet', style: AppTextStyles.subHeading),
            const SizedBox(height: 8),
            Text(
              'Create your store first to manage products.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateStoreScreen()),
                );
                if (mounted) {
                  setState(() => _loadingStore = true);
                  await context.read<StoreProvider>().loadMyStore();
                  if (mounted) setState(() => _loadingStore = false);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.primaryGradient,
                ),
                child: const Text(
                  'Create My Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Halke tairte hue glows ----------
  Widget _ambientOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryViolet.withValues(alpha: 0.10),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.12, 0.12),
              end: const Offset(-0.12, -0.1),
              duration: 7000.ms,
              curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 80,
          left: -70,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.06),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(-0.1, -0.1),
              end: const Offset(0.12, 0.12),
              duration: 8000.ms,
              curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _productRow(BuildContext context, Product p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p.images.isNotEmpty ? p.images.first : '',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.surface2,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rs ${p.price.toStringAsFixed(0)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _stockChip(p.stock),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.edit_outlined, color: AppColors.primaryViolet),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, p),
          ),
        ],
      ),
    );
  }

  // Stock kam ho to red chip, warna green
  Widget _stockChip(int stock) {
    final low = stock <= 5;
    final color = low ? Colors.redAccent : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        low ? 'Low: $stock' : 'Stock: $stock',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.05, 1.05),
        duration: 1200.ms,
        curve: Curves.easeInOut);
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete product?', style: AppTextStyles.subHeading),
        content: Text('"${p.name}" will be permanently deleted.',
            style: AppTextStyles.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.caption),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProductProvider>().deleteProduct(p.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted.')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
