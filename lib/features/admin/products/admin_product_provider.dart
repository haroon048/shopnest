import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../models/product.dart';

// Admin: products ka poora CRUD (live streams ke saath)
class AdminProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _saving = false;
  bool get saving => _saving;

  // Saare products (live)
  Stream<List<Product>> productsStream() => _db
      .collection('products')
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromMap(d.data(), d.id)).toList());

  // Categories (form ke dropdown ke liye, live)
  Stream<List<Category>> categoriesStream() => _db
      .collection('categories')
      .snapshots()
      .map((s) => s.docs.map((d) => Category.fromMap(d.data(), d.id)).toList());

  // Naya product add ya purana update (id == null matlab naya)
  Future<bool> saveProduct({
    String? id,
    required String name,
    required double price,
    double? oldPrice,
    required int stock,
    required String categoryId,
    required String description,
    required String imageUrl,
    required String sellerId,
    required String storeId,
  }) async {
    _saving = true;
    notifyListeners();
    try {
      final data = {
        'name': name,
        'price': price,
        'oldPrice': oldPrice,
        'stock': stock,
        'categoryId': categoryId,
        'description': description,
        'images': [imageUrl],
        'sellerId': sellerId,
        'storeId': storeId,
        'isFlashDeal': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (id == null) {
        data['rating'] = 0;
        data['ratingCount'] = 0;
        await _db.collection('products').add(data);
      } else {
        // rating aur createdAt ko mat chhero
        await _db.collection('products').doc(id).update(data);
      }
      return true;
    } catch (e) {
      debugPrint('SAVE PRODUCT ERROR: $e'); // <-- ye line
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // Product delete
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }
}
