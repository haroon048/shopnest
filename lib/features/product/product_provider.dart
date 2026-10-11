import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Product detail ke liye live streams.
// StreamBuilder inhe sunega - data badalte hi screen update ho jayegi.
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ek product ka live data (stock waghera update hota rahega)
  Stream<DocumentSnapshot> productStream(String id) {
    return _db.collection('products').doc(id).snapshots();
  }

  // Us product ke reviews (naya review aate hi list update)
  Stream<QuerySnapshot> reviewsStream(String id) {
    return _db
        .collection('products')
        .doc(id)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
