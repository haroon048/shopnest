import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/store.dart';
import 'store_provider.dart';

// Customer ke liye: saare stores ki list — jisme shopping karni hai wo chuno.
class StorePickerScreen extends StatefulWidget {
  const StorePickerScreen({super.key});

  @override
  State<StorePickerScreen> createState() => _StorePickerScreenState();
}

class _StorePickerScreenState extends State<StorePickerScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStores();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openStore(Store store) {
    context.read<StoreProvider>().selectStore(store);
    Navigator.pushNamed(context, AppRoutes.shop);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Choose a Store', style: AppTextStyles.subHeading),
        centerTitle: true,
      ),
      body: Consumer<StoreProvider>(
        builder: (context, sp, _) {
          if (sp.isLoading && sp.stores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Search filter (naam ya category se)
          final shown = sp.stores.where((s) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: AppColors.primaryViolet,
                  decoration: InputDecoration(
                    hintText: 'Search stores...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primaryViolet,
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _storeCard(shown[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Ek store ka card
  Widget _storeCard(Store store) {
    return GestureDetector(
      onTap: () => _openStore(store),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface.withValues(alpha: 0.75),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Logo (image ho to image, warna initial letter)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              alignment: Alignment.center,
              child: store.logoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        store.logoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Text(store.initial, style: _initialStyle),
                      ),
                    )
                  : Text(store.initial, style: _initialStyle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(store.category, style: AppTextStyles.caption),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${store.rating.toStringAsFixed(1)} (${store.ratingCount})',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppColors.primaryGradient,
              ),
              child: const Text(
                'Visit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('No stores yet', style: AppTextStyles.subHeading),
            const SizedBox(height: 6),
            Text(
              'Be the first to open a store!',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  static const _initialStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
}
