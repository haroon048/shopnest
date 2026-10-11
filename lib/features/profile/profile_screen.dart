import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glowing_textfield.dart';
import '../../models/order.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';
import '../orders/orders_provider.dart';
import '../wishlist/wishlist_provider.dart';

// Worldwide-style profile: dramatic banner, glowing avatar,
// gradient stat cards, grouped menu, bold logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false; // photo upload ho rahi hai?

  // Gallery se photo chun kar Cloudinary par upload karo
  Future<void> _changePhoto(AuthProvider auth) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final url = await CloudinaryService.uploadImage(picked);
      await auth.updatePhoto(url!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload the photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // Naam badalne ka premium popup
  void _editName(AuthProvider auth) {
    final ctrl = TextEditingController(text: auth.user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit name',
                  style: AppTextStyles.subHeading
                      .copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'This name shows on your orders and chats.',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              GlowingTextField(hint: 'Your name', controller: ctrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Center(
                            child: Text('Cancel',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textMuted))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final name = ctrl.text.trim();
                        if (name.isEmpty) return;
                        await auth.updateName(name);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryViolet
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Center(
                            child: Text('Save',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate()
          .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              duration: 280.ms,
              curve: Curves.easeOutBack)
          .fadeIn(duration: 220.ms),
    );
  }

  // About dialog (custom, dark-theme)
  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryViolet.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                    child: Text('S',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800))),
              ),
              const SizedBox(height: 16),
              const Text('ShopNest',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Version 1.0.0',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Text(
                'Your premium shopping destination — curated products, flash deals and lightning-fast delivery.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                      child: Text('Close',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack)
          .fadeIn(duration: 250.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _bannerHeader()),
          SliverToBoxAdapter(child: _identity(auth, user?.name, user?.email)),
          SliverToBoxAdapter(child: _statCards()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
              child: _menuSection('Account', [
            _MenuEntry(Icons.person_outline_rounded, 'Edit Name',
                'Update your display name', () => _editName(auth)),
            _MenuEntry(Icons.photo_camera_outlined, 'Change Photo',
                'Update your profile picture', () => _changePhoto(auth)),
          ])),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
              child: _menuSection('Shopping', [
            _MenuEntry(
                Icons.receipt_long_rounded,
                'My Orders',
                'Track and manage your orders',
                () => Navigator.pushNamed(context, AppRoutes.orders)),
            _MenuEntry(
                Icons.favorite_rounded,
                'My Wishlist',
                'Products you have saved',
                () => Navigator.pushNamed(context, AppRoutes.wishlist)),
          ])),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
              child: _menuSection('General', [
            _MenuEntry(Icons.info_outline_rounded, 'About ShopNest',
                'Version and app info', _showAbout),
          ])),
          SliverToBoxAdapter(child: _logout(auth)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Center(
                  child: Text('ShopNest v1.0.0',
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10, color: AppColors.textMuted))),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Dramatic gradient banner + avatar ----------
  Widget _bannerHeader() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    return SizedBox(
      height: 264,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 204,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryViolet,
                  AppColors.primaryPink,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryViolet.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: -70,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Floating sparkle dots
                Positioned(
                  right: 60,
                  top: 40,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      duration: 2000.ms),
                ),
                Positioned(
                  left: 90,
                  top: 90,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.6, 1.6),
                      duration: 2400.ms),
                ),
                Positioned(
                  top: 14,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile',
                          style: AppTextStyles.heading
                              .copyWith(fontSize: 22, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Member',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(child: _avatar(auth, user?.photoUrl, user?.name)),
          ),
        ],
      ),
    );
  }

  // ---------- Avatar (tap = photo change, glow ring) ----------
  Widget _avatar(AuthProvider auth, String? photoUrl, String? name) {
    return GestureDetector(
      onTap: () => _changePhoto(auth),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryViolet.withValues(alpha: 0.5),
                  blurRadius: 24,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surface2,
              backgroundImage: (photoUrl?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(photoUrl!)
                  : null,
              child: (photoUrl?.isEmpty ?? true)
                  ? Text(
                      (name?.isNotEmpty ?? false)
                          ? name![0].toUpperCase()
                          : '?',
                      style: AppTextStyles.display,
                    )
                  : null,
            ),
          ),
          if (_uploading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryViolet,
                ),
              ),
            ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child:
                  const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms);
  }

  // ---------- Name + email + pills ----------
  Widget _identity(AuthProvider auth, String? name, String? email) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Text(name ?? '',
                style: AppTextStyles.subHeading
                    .copyWith(fontSize: 20, fontWeight: FontWeight.bold))
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Text(email ?? '',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted))
            .animate()
            .fadeIn(delay: 260.ms, duration: 400.ms),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _editName(auth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryViolet.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Edit Profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 320.ms, duration: 400.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            delay: 320.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack),
      ],
    );
  }

  // ---------- Gradient stat cards ----------
  Widget _statCards() {
    final wish = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final orders = context.read<OrdersProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: orders.ordersStream(),
              builder: (context, snap) => _statCard(
                '${snap.data?.length ?? 0}',
                'Orders',
                Icons.receipt_long_rounded,
                const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              '${wish.count}',
              'Wishlist',
              Icons.favorite_rounded,
              const [Color(0xFFEC4899), Color(0xFFF43F5E)],
              1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              '${cart.itemCount}',
              'Cart',
              Icons.shopping_bag_rounded,
              const [Color(0xFF38BDF8), Color(0xFF8B5CF6)],
              2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon,
      List<Color> colors, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.subHeading
                  .copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (300 + index * 90).ms, duration: 450.ms)
        .slideY(
            begin: 0.3,
            end: 0,
            delay: (300 + index * 90).ms,
            duration: 450.ms,
            curve: Curves.easeOutBack)
        .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            delay: (300 + index * 90).ms,
            duration: 450.ms);
  }

  // ---------- Grouped menu section (iOS style) ----------
  Widget _menuSection(String title, List<_MenuEntry> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                letterSpacing: 1.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
          ),
        ).animate().fadeIn(duration: 400.ms),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _menuRow(items[i], i),
                if (i != items.length - 1)
                  Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 16,
                      color: Colors.white.withValues(alpha: 0.06)),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.15, end: 0, duration: 450.ms),
      ],
    );
  }

  Widget _menuRow(_MenuEntry e, int i) {
    return GestureDetector(
      onTap: e.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryViolet.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(e.icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(e.subtitle,
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (i * 70).ms, duration: 350.ms)
        .slideX(begin: 0.15, end: 0, delay: (i * 70).ms, duration: 350.ms);
  }

  // ---------- Bold gradient logout ----------
  Widget _logout(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: GestureDetector(
        onTap: () async {
          await auth.signOut();
          if (context.mounted) {
            // Logout ke baad role select screen (Customer / Admin Panel)
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.roleSelect,
              (_) => false,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                colors: [Color(0xFFF43F5E), Color(0xFFEC4899)]),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Logout',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 450.ms)
          .slideY(begin: 0.2, end: 0, duration: 450.ms),
    );
  }
}

// Menu row ka data.
class _MenuEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _MenuEntry(this.icon, this.title, this.subtitle, this.onTap);
}
