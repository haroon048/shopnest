import 'package:cloud_firestore/cloud_firestore.dart';

// Ek store = ek dukaan. Har buyer ka apna store hota hai.
// Saara data (products, orders, chats) isi ke storeId se alag rehta hai.
class Store {
  final String id;
  final String ownerId; // jis user ne store banaya (uski uid)
  final String name;
  final String category;
  final String description;
  final String logoUrl; // khaali ho sakta hai (tab initial letter dikhega)
  final double rating;
  final int ratingCount;
  final bool isActive;
  final DateTime? createdAt;

  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.category = 'General',
    this.description = '',
    this.logoUrl = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  // Firestore doc -> Store
  factory Store.fromMap(Map<String, dynamic> map, String id) {
    return Store(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? 'My Store',
      category: map['category'] as String? ?? 'General',
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Store -> Firestore doc
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'logoUrl': logoUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Logo na ho to naam ka pehla letter dikhao
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'S';
}
