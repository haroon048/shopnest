import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

import '../../../models/order.dart';

/// The order statuses used across the app.
class OrderStatuses {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const all = [pending, confirmed, shipped, delivered, cancelled];
}

/// Admin order management: live list of every order + status updates.
/// Only admins reach this provider (route + Firestore rules guard it).
class AdminOrderProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  /// Every order, newest first — LIVE.
  Stream<List<Order>> get ordersStream {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Order.fromMap(d.data(), d.id)).toList());
  }

  /// Single order as a LIVE stream — the detail screen uses this so the
  /// status pill updates itself the moment the admin changes it.
  Stream<Order?> orderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((d) => d.data() == null ? null : Order.fromMap(d.data()!, d.id));
  }

  /// Update the order status. The customer's tracking screen listens to
  /// this same document, so it moves live with zero extra code.
  /// Returns null on success, error message on failure.
  Future<String?> updateStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      return null;
    } catch (e) {
      return 'Failed to update status: $e';
    }
  }
}
