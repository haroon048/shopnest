import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';

// User ka cart. Firestore se live sync hota hai:
// users/{uid}/cart/{productId}
class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _sub; // live listener
  String? _uid;

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  String? _promoCode;
  String? get promoCode => _promoCode;

  // Promo codes: code -> kitne percent off
  static const _promos = {'WELCOME10': 10.0, 'SAVE20': 20.0};

  // Asal uid: pehle ProxyProvider wala, na mile to Firebase se direct.
  // (App restart par AuthProvider ka user null reh sakta hai — ye fallback
  // us surat me bhi cart ko kaam karta rakhta hai.)
  String? get _effectiveUid => _uid ?? FirebaseAuth.instance.currentUser?.uid;

  // Login/logout par main.dart se naya uid aata hai (ProxyProvider).
  void setUser(String? uid) {
    if (_uid == uid) return; // same user, dobara sunne ki zaroorat nahi
    _uid = uid;
    _sub?.cancel(); // purana listener band
    _items = [];
    _promoCode = null;
    if (uid == null) {
      notifyListeners(); // logout: cart khaali dikhao
      return;
    }
    _listenToCart(uid);
    notifyListeners();
  }

  // Is user ke cart ko live suno (kahin se bhi change ho, screen update)
  void _listenToCart(String uid) {
    _sub?.cancel();
    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen((snap) {
      _items = snap.docs.map((d) => CartItem.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    });
  }

  CollectionReference _cartCol(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  // Badge ke liye: kul kitni cheezen hain
  int get itemCount => _items.fold(0, (sum, i) => sum + i.qty);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.total);

  // 5000+ par delivery free, warna 199
  double get deliveryFee => _items.isEmpty || subtotal >= 5000 ? 0 : 199;

  double get discount {
    if (_promoCode == null) return 0;
    return subtotal * (_promos[_promoCode]! / 100);
  }

  double get total => subtotal - discount + deliveryFee;

  // Product cart me daalo (pehle se hai to quantity +1)
  Future<void> addToCart(Product p) async {
    final uid = _effectiveUid;
    if (uid == null) {
      // Ab khamoshi se nahi — saaf batao ke login chahiye
      throw 'Please log in again to add items to your cart.';
    }
    if (_uid == null) {
      // Listener nahi laga hua to ab lagao taake screen foran update ho
      _uid = uid;
      _listenToCart(uid);
    }
    final doc = _cartCol(uid).doc(p.id);
    final snap = await doc.get();
    if (snap.exists) {
      final old = CartItem.fromMap(snap.data() as Map<String, dynamic>, p.id);
      await doc.update({'qty': old.qty + 1});
    } else {
      await doc.set(CartItem(
        productId: p.id,
        name: p.name,
        price: p.price,
        image: p.images.isNotEmpty ? p.images.first : '',
        qty: 1,
      ).toMap());
    }
    // Live listener khud nayi list utha lega — screen update ho jayegi
  }

  // Quantity badlo (0 ho to item delete)
  Future<void> updateQty(String productId, int qty) async {
    final uid = _effectiveUid;
    if (uid == null) return;
    if (qty <= 0) {
      await removeFromCart(productId);
      return;
    }
    await _cartCol(uid).doc(productId).update({'qty': qty});
  }

  Future<void> removeFromCart(String productId) async {
    final uid = _effectiveUid;
    if (uid == null) return;
    await _cartCol(uid).doc(productId).delete();
  }

  Future<void> clearCart() async {
    final uid = _effectiveUid;
    if (uid == null) return;
    final snap = await _cartCol(uid).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  // Promo code lagao. Sahi hua to true.
  bool applyPromo(String code) {
    code = code.trim().toUpperCase();
    if (_promos.containsKey(code)) {
      _promoCode = code;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromo() {
    _promoCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
