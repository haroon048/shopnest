import 'package:cloud_firestore/cloud_firestore.dart';

// Firestore ke 'products' collection ka model
class Product {
  final String id;
  final String name;
  final double price;
  final double? oldPrice; // discount se pehle wali price
  final List<String> images;
  final String categoryId;
  final String sellerId;
  final int stock;
  final double rating;
  final int ratingCount;
  final bool isFlashDeal;
  final DateTime? dealEndsAt; // flash deal kab khatam hogi
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.images,
    required this.categoryId,
    required this.sellerId,
    required this.stock,
    required this.rating,
    required this.ratingCount,
    required this.isFlashDeal,
    this.dealEndsAt,
    required this.description,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      oldPrice: map['oldPrice'] != null ? (map['oldPrice']).toDouble() : null,
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      stock: map['stock'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isFlashDeal: map['isFlashDeal'] ?? false,
      dealEndsAt: map['dealEndsAt'] != null
          ? (map['dealEndsAt'] as Timestamp).toDate()
          : null,
      description: map['description'] ?? '',
    );
  }
}
