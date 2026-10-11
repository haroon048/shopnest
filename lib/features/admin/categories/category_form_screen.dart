import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../../models/category.dart';
import 'admin_category_provider.dart';

/// New category or edit existing — name + Cloudinary image upload.
class CategoryFormScreen extends StatefulWidget {
  final Category? category; // null = new, otherwise edit
  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _nameCtrl = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _imageUrl = widget.category!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Pick from gallery → upload to Cloudinary → keep the URL
  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploading = true);
    // NOTE: use your CloudinaryService's actual upload method name here
    final url = await CloudinaryService.uploadImage(picked);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed')),
      );
      return;
    }
    setState(() => _imageUrl = url);
  }

  Future<void> _save() async {
    final error = await context.read<AdminCategoryProvider>().saveCategory(
          id: widget.category?.id,
          name: _nameCtrl.text,
          imageUrl: _imageUrl ?? '',
        );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category saved successfully')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<AdminCategoryProvider>().saving;
    final isEdit = widget.category != null;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Category' : 'New Category'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image picker box
            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : _imageUrl == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: Color(0xFF8B5CF6), size: 40),
                              SizedBox(height: 8),
                              Text('Tap to add category image',
                                  style: TextStyle(color: Colors.white54)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(_imageUrl!,
                                fit: BoxFit.cover, width: double.infinity),
                          ),
              ),
            ),
            const SizedBox(height: 20),
            // Name field
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category name',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Save button (gradient)
            GestureDetector(
              onTap: saving ? null : _save,
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 20),
                  ],
                ),
                child: Center(
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Category' : 'Add Category',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
