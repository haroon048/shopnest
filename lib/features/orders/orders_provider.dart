import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

import '../../models/order.dart';

// User ke orders. Live list + ek order ka live detail.
class OrdersProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _uid;

  // Login/logout par main.dart se naya uid aata hai (ProxyProvider).
  void setUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    notifyListeners();
  }

  // Mere orders (naya order sab se pehle).
  // Composite index se bachne ke liye sorting app me ki hai.
  Stream<List<Order>> ordersStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Order.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => (b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return list;
    });
  }

  // Kisi store ke orders (seller ke liye — uske store ka dashboard).
  // Single where + Dart sorting (composite index nahi chahiye).
  Stream<List<Order>> storeOrdersStream(String storeId) {
    if (storeId.isEmpty) return const Stream.empty();
    return _db
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Order.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => (b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return list;
    });
  }

  // Ek order ka live data (status change ho to screen khud update).
  Stream<Order?> orderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((d) => d.data() == null ? null : Order.fromMap(d.data()!, d.id));
  }
}
