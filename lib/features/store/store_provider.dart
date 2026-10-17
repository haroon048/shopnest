import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/store.dart';

// Stores ka data: saare stores, mera store, customer ka selected store.
class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Store> _stores = [];
  Store? _myStore;
  Store? _selectedStore;
  bool _isLoading = false;
  String? _error;

  List<Store> get stores => _stores;
  Store? get myStore => _myStore;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mere store ke stats (dashboard ke liye)
  int _myProducts = 0;
  int _myOrders = 0;
  double _myRevenue = 0.0;
  bool _statsLoading = false;

  int get myProducts => _myProducts;
  int get myOrders => _myOrders;
  double get myRevenue => _myRevenue;
  bool get statsLoading => _statsLoading;

  // Customer ke liye: saare active stores lao
  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('stores')
          .where('isActive', isEqualTo: true)
          .get();
      _stores = snap.docs.map((d) => Store.fromMap(d.data(), d.id)).toList();
      // Naye stores pehle (Dart me sort — composite index ki zaroorat nahi)
      _stores.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    } catch (e) {
      _error = 'Could not load stores. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mera store (jahan main owner hun) lao
  Future<void> loadMyStore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await _db
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _myStore = Store.fromMap(snap.docs.first.data(), snap.docs.first.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadMyStore failed: $e');
    }
  }

  // Store logo Cloudinary par upload karo (ShopNest wala unsigned preset).
  // Kaamyaab hua to image URL milta hai, warna null.
  Future<String?> uploadStoreLogo(XFile image) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/kdgf3mee/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'shopnest_unsigned'
        ..files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await http.Response.fromStream(response);
        final data = jsonDecode(body.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }
    } catch (e) {
      debugPrint('uploadStoreLogo failed: $e');
    }
    return null;
  }

  // Naya store banao. true = ban gaya.
  Future<bool> createStore({
    required String name,
    required String category,
    String description = '',
    String logoUrl = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _error = 'Please log in again to create a store.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Ek user ka ek hi store (duplicate rokne ke liye)
      final existing = await _db
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        _myStore =
            Store.fromMap(existing.docs.first.data(), existing.docs.first.id);
        _error = 'You already have a store.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final store = Store(
        id: '',
        ownerId: uid,
        name: name.trim(),
        category: category,
        description: description.trim(),
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
      );
      final ref = await _db.collection('stores').add(store.toMap());
      _myStore = Store.fromMap(store.toMap(), ref.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Could not create store. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mere store ke stats lao:
  // Products: sellerId se (abhi live) — Step 3 me storeId par shift hoga.
  // Orders/Revenue: storeId se — orders par storeId Step 3 me lagega.
  Future<void> loadMyStoreStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _statsLoading = true;
    notifyListeners();
    try {
      final p = await _db
          .collection('products')
          .where('sellerId', isEqualTo: uid)
          .get();
      _myProducts = p.docs.length;

      final storeId = _myStore?.id;
      if (storeId != null && storeId.isNotEmpty) {
        final o = await _db
            .collection('orders')
            .where('storeId', isEqualTo: storeId)
            .get();
        _myOrders = o.docs.length;
        double total = 0;
        for (final d in o.docs) {
          final m = d.data();
          total += (m['total'] as num?)?.toDouble() ??
              (m['totalAmount'] as num?)?.toDouble() ??
              0;
        }
        _myRevenue = total;
      }
    } catch (e) {
      debugPrint('loadMyStoreStats failed: $e');
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  // Customer ne konsa store select kiya
  void selectStore(Store store) {
    _selectedStore = store;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
