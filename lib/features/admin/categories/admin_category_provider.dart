import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/category.dart';

/// Categories for the admin: live list + add/edit/delete.
/// Write permission is controlled by isAdmin() in Firestore rules.
class AdminCategoryProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool _saving = false;
  bool get saving => _saving;

  /// LIVE stream of all categories — the screen updates itself
  /// when the admin changes anything, and the shop sees it instantly.
  Stream<List<Category>> get categoriesStream {
    return _db.collection('categories').orderBy('name').snapshots().map(
        (snap) =>
            snap.docs.map((d) => Category.fromMap(d.data(), d.id)).toList());
  }

  /// Add new (id null) or edit existing. null = success, String = error.
  Future<String?> saveCategory({
    String? id,
    required String name,
    required String imageUrl,
  }) async {
    if (name.trim().isEmpty) return 'Please enter the category name';
    if (imageUrl.trim().isEmpty) return 'Please add a category image';
    _saving = true;
    notifyListeners();
    try {
      final data = {'name': name.trim(), 'imageUrl': imageUrl.trim()};
      if (id == null) {
        await _db.collection('categories').add(data);
      } else {
        await _db.collection('categories').doc(id).update(data);
      }
      return null;
    } catch (e) {
      return 'Failed to save: $e';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Safety check before delete: block it if any product uses
  /// this category, so no product is left orphaned.
  Future<String?> deleteCategory(String id) async {
    try {
      final used = await _db
          .collection('products')
          .where('categoryId', isEqualTo: id) // match your model's field name
          .limit(1)
          .get();
      if (used.docs.isNotEmpty) {
        return 'This category has products. Move or delete them first.';
      }
      await _db.collection('categories').doc(id).delete();
      return null;
    } catch (e) {
      return 'Failed to delete: $e';
    }
  }
}
