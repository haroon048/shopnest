import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/product_card.dart';
import '../home/home_provider.dart';
import 'wishlist_provider.dart';

// Wishlist tab: dil (heart) ki hui products ka grid.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wish = context.watch<WishlistProvider>();
    final home = context.watch<HomeProvider>();
    // Sirf wahi products jo fav bhi hain aur abhi bhi maujood bhi hain
    final favs = home.products.where((p) => wish.isFav(p.id)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Wishlist', style: AppTextStyles.heading),
      ),
      body: favs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/placeholders/empty_wishlist.png',
                      height: 140,
                    ),
                    const SizedBox(height: 12),
                    Text('Your wishlist is empty',
                        style: AppTextStyles.subHeading),
                    const SizedBox(height: 6),
                    Text(
                      'Save products here by tapping the heart button.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, i) => ProductCard(product: favs[i]),
            ),
    );
  }
}
