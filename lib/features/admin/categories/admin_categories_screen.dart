import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/category.dart';
import 'admin_category_provider.dart';
import 'category_form_screen.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCategoryProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Categories', style: AppTextStyles.heading)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.2, end: 0, duration: 400.ms),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Add category',
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add, color: Colors.white),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.12, 1.12),
                duration: 1600.ms,
                curve: Curves.easeInOut),
          ),
        ],
      ),
      body: Stack(
        children: [
          _ambientOrbs(),
          StreamBuilder<List<Category>>(
            stream: provider.categoriesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load categories: ${snapshot.error}',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryViolet,
                  ),
                );
              }

              final categories = snapshot.data!;
              if (categories.isEmpty) {
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
                        child: const Icon(Icons.category_outlined,
                            size: 38, color: AppColors.primaryViolet),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.06, 1.06),
                          duration: 1600.ms,
                          curve: Curves.easeInOut),
                      const SizedBox(height: 14),
                      Text('No categories yet. Add your first category.',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center),
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
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _categoryTile(context, categories[index], index)
                        .animate()
                        .fadeIn(delay: (index * 70).ms, duration: 350.ms)
                        .slideX(
                          begin: 0.25,
                          end: 0,
                          delay: (index * 70).ms,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          delay: (index * 70).ms,
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

  // ---------- Halke tairte hue glows ----------
  Widget _ambientOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryViolet.withValues(alpha: 0.10),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(-0.12, 0.12),
              end: const Offset(0.12, -0.1),
              duration: 7000.ms,
              curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 80,
          right: -70,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.06),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.1, -0.1),
              end: const Offset(-0.12, 0.12),
              duration: 8000.ms,
              curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _categoryTile(BuildContext context, Category category, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: category.imageUrl.isEmpty
                ? const Icon(Icons.category_outlined,
                    color: AppColors.primaryViolet)
                : Image.network(
                    category.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.04, 1.04),
            duration: (1400 + index * 120).ms,
            curve: Curves.easeInOut),
        title: Text(category.name, style: AppTextStyles.body),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _openForm(context, category: category);
            } else if (value == 'delete') {
              _confirmDelete(context, category);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Category? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(category: category),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete category?', style: AppTextStyles.subHeading),
        content: Text(
          'Delete "${category.name}"? Categories used by products cannot be deleted.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error =
        await context.read<AdminCategoryProvider>().deleteCategory(category.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Category deleted successfully.'),
      ),
    );
  }
}
