import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Dashboard ke live stats (sab Firestore streams se)
class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kul orders ki tadaad (live)
  Stream<int> ordersCount() =>
      _db.collection('orders').snapshots().map((s) => s.docs.length);

  // Kul revenue (cancelled orders ko chhor kar, live)
  Stream<double> totalRevenue() =>
      _db.collection('orders').snapshots().map((s) {
        double sum = 0;
        for (final d in s.docs) {
          final data = d.data();
          if (data['status'] == 'cancelled') continue;
          sum += (data['total'] as num?)?.toDouble() ?? 0;
        }
        return sum;
      });

  // Kul products (live)
  Stream<int> productsCount() =>
      _db.collection('products').snapshots().map((s) => s.docs.length);

  // Kul users (live)
  Stream<int> usersCount() =>
      _db.collection('users').snapshots().map((s) => s.docs.length);

  // Taaza tareen 5 orders (live)
  Stream<QuerySnapshot> recentOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots();
}
