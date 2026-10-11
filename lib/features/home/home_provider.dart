import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/product.dart';

// Home screen ka data: categories + products Firestore se.
class HomeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  List<Product> get flashDeals =>
      _products.where((p) => p.isFlashDeal).toList();
  bool get loading => _loading;
  String? get error => _error;

  HomeProvider() {
    load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final catSnap = await _db.collection('categories').get();
      _categories =
          catSnap.docs.map((d) => Category.fromMap(d.data(), d.id)).toList();

      final prodSnap = await _db.collection('products').get();
      _products =
          prodSnap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      _error = 'Could not load data. Check your internet connection.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(); // pull-to-refresh ke liye
}
