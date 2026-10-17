import 'package:cloud_firestore/cloud_firestore.dart';

import 'address.dart';

// Order ka ek item
class OrderItem {
  final String productId;
  final String name;
  final double price;
  final String image;
  final int qty;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.qty,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      image: map['image'] ?? '',
      qty: map['qty'] ?? 1,
    );
  }
}

// Order. Firestore: orders/{orderId}
class Order {
  final String id;
  final String userId;
  final String storeId; // order kis store ka hai
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final Address address;
  final String paymentMethod; // cod
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.userId,
    this.storeId = '',
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  // Status ka padhne layak naam
  String get statusText {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      address:
          Address.fromMap(Map<String, dynamic>.from(map['address'] ?? {}), ''),
      paymentMethod: map['paymentMethod'] ?? 'cod',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
