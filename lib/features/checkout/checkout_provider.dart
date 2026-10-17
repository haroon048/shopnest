import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/address.dart';
import '../cart/cart_provider.dart';
import '../../core/services/notification_service.dart';

// Checkout: address chunna, payment method, order place karna.
class CheckoutProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;
  String? _uid;

  List<Address> _addresses = [];
  List<Address> get addresses => _addresses;

  Address? _selected;
  Address? get selectedAddress => _selected;

  final String _paymentMethod = 'cod'; // abhi sirf Cash on Delivery
  String get paymentMethod => _paymentMethod;

  bool _placing = false; // order place ho raha hai?
  bool get placing => _placing;

  // Login/logout par main.dart se naya uid aata hai (ProxyProvider).
  void setUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _addresses = [];
    _selected = null;
    if (uid == null) {
      notifyListeners();
      return;
    }
    _sub = _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .listen((snap) {
      _addresses =
          snap.docs.map((d) => Address.fromMap(d.data(), d.id)).toList();
      // Koi select nahi to pehla auto-select
      if (_selected == null && _addresses.isNotEmpty) {
        _selected = _addresses.first;
      }
      // Selected delete ho gaya ho to pehla chun lo
      if (_selected != null && !_addresses.any((a) => a.id == _selected!.id)) {
        _selected = _addresses.isNotEmpty ? _addresses.first : null;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void selectAddress(Address a) {
    _selected = a;
    notifyListeners();
  }

  Future<void> addAddress(Address a) async {
    if (_uid == null) return;
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .add(a.toMap());
    // Naya address foran select kar lo
    _selected = Address(
      id: ref.id,
      label: a.label,
      name: a.name,
      phone: a.phone,
      street: a.street,
      city: a.city,
    );
    notifyListeners();
  }

  Future<void> deleteAddress(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('addresses')
        .doc(id)
        .delete();
  }

  // Order place karo. Kamyab hua to orderId milega, warna null.
  // Ek hi batch me: order banao + stock ghatao
  // (ya to dono honge, ya kuch nahi - aadha order nahi banega).
  Future<String?> placeOrder(CartProvider cart) async {
    if (_uid == null || _selected == null || cart.items.isEmpty) {
      return null;
    }
    _placing = true;
    notifyListeners();
    try {
      final orderRef = _db.collection('orders').doc();
      final batch = _db.batch();
      // Customer ek waqt me ek hi store se shopping karta hai,
      // is liye order ka storeId pehle item se le lo.
      final orderStoreId =
          cart.items.isNotEmpty ? cart.items.first.storeId : '';
      batch.set(orderRef, {
        'userId': _uid,
        'storeId': orderStoreId, // order kis store ka hai
        'items': cart.items
            .map((i) => {
                  'productId': i.productId,
                  'name': i.name,
                  'price': i.price,
                  'image': i.image,
                  'qty': i.qty,
                })
            .toList(),
        'subtotal': cart.subtotal,
        'deliveryFee': cart.deliveryFee,
        'discount': cart.discount,
        'promoCode': cart.promoCode,
        'total': cart.total,
        'address': _selected!.toMap(),
        'paymentMethod': _paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Har product ka stock ghatao
      for (final i in cart.items) {
        batch.update(
          _db.collection('products').doc(i.productId),
          {'stock': FieldValue.increment(-i.qty)},
        );
      }
      await batch.commit();
      // Store owner ko notification (naya order aaya hai).
      // cart.clearCart() se pehle — uske baad total 0 ho jayega.
      if (orderStoreId.isNotEmpty) {
        final storeDoc = await _db.collection('stores').doc(orderStoreId).get();
        final ownerId = storeDoc.data()?['ownerId'] as String?;
        if (ownerId != null && ownerId.isNotEmpty && ownerId != _uid) {
          await NotificationService.createNotification(
            userId: ownerId,
            title: 'New order received',
            body: 'You have a new order worth Rs ${cart.total.toInt()}.',
            type: 'order',
            refId: orderRef.id,
          );
        }
      }
      await cart.clearCart(); // order ban gaya, cart khaali karo
      return orderRef.id;
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
