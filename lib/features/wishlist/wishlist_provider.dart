import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Wishlist: users/{uid}/wishlist/{productId} me sirf IDs save hoti hain.
class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;
  String? _uid;

  Set<String> _ids = {}; // fav product IDs
  Set<String> get ids => _ids;
  int get count => _ids.length;

  // Login/logout par main.dart se naya uid aata hai (ProxyProvider).
  void setUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _ids = {};
    if (uid == null) {
      notifyListeners();
      return;
    }
    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .snapshots()
        .listen((snap) {
      _ids = snap.docs.map((d) => d.id).toSet();
      notifyListeners();
    });
    notifyListeners();
  }

  bool isFav(String productId) => _ids.contains(productId);

  // Heart dabao: fav hai to hatao, nahi to add karo
  Future<void> toggleFav(String productId) async {
    if (_uid == null) return;
    final doc =
        _db.collection('users').doc(_uid).collection('wishlist').doc(productId);
    if (_ids.contains(productId)) {
      await doc.delete();
    } else {
      await doc.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
