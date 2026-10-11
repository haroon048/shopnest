import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glowing_textfield.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../auth/auth_provider.dart';
import 'admin_product_provider.dart';

// Naya product add ya purana edit — dono kaam aik screen
class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = naya product
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _oldPrice = TextEditingController();
  final _stock = TextEditingController();
  final _desc = TextEditingController();

  String? _categoryId;
  XFile? _pickedImage; // nayi chuni hui photo
  bool _uploading = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Edit mode: purani values bhar do
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _price.text = p.price.toStringAsFixed(0);
      if (p.oldPrice != null) {
        _oldPrice.text = p.oldPrice!.toStringAsFixed(0);
      }
      _stock.text = '${p.stock}';
      _desc.text = p.description;
      _categoryId = p.categoryId.isNotEmpty ? p.categoryId : null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _oldPrice.dispose();
    _stock.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    if (name.isEmpty || price == null || stock == null || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name, price, stock, and category are required.')),
      );
      return;
    }

    // Photo: nayi chuni to Cloudinary par upload karo
    String imageUrl = (widget.product?.images.isNotEmpty ?? false)
        ? widget.product!.images.first
        : '';
    if (_pickedImage != null) {
      setState(() => _uploading = true);
      final url = await CloudinaryService.uploadImage(_pickedImage!);
      setState(() => _uploading = false);
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not upload the photo.')),
          );
        }
        return;
      }
      imageUrl = url;
    }
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A product photo is required.')),
      );
      return;
    }

    final sellerId = context.read<AuthProvider>().user!.uid;
    final ok = await context.read<AdminProductProvider>().saveProduct(
          id: widget.product?.id,
          name: name,
          price: price,
          oldPrice: double.tryParse(_oldPrice.text.trim()),
          stock: stock,
          categoryId: _categoryId!,
          description: _desc.text.trim(),
          imageUrl: imageUrl,
          sellerId: sellerId,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Product updated successfully.'
                : 'Product added successfully.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save the product. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProductProvider>();
    final busy = admin.saving || _uploading;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEdit ? 'Edit Product' : 'New Product',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker
            GestureDetector(
              onTap: busy ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryViolet.withValues(alpha: 0.4),
                  ),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_pickedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : (widget.product?.images.isNotEmpty ?? false)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.product!.images.first,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('Choose a photo',
                                  style: AppTextStyles.caption),
                            ],
                          ),
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            GlowingTextField(hint: 'Product name', controller: _name),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlowingTextField(
                    hint: 'Price (Rs)',
                    controller: _price,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlowingTextField(
                    hint: 'Old price (optional)',
                    controller: _oldPrice,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlowingTextField(
              hint: 'Stock (quantity)',
              controller: _stock,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Category dropdown (live)
            StreamBuilder<List<Category>>(
              stream: admin.categoriesStream(),
              builder: (context, snap) {
                final cats = snap.data ?? [];
                final categoryItems = cats
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList();
                if (_categoryId != null &&
                    !cats.any((category) => category.id == _categoryId)) {
                  categoryItems.add(
                    DropdownMenuItem<String>(
                      value: _categoryId,
                      child: const Text('Unavailable category'),
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categoryId,
                      hint: Text('Choose a category',
                          style: AppTextStyles.caption),
                      dropdownColor: AppColors.surface,
                      isExpanded: true,
                      style: AppTextStyles.body,
                      items: categoryItems,
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            GlowingTextField(hint: 'Description', controller: _desc),
            const SizedBox(height: 20),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: busy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Update Product' : 'Add Product',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms),
      ),
    );
  }
}
