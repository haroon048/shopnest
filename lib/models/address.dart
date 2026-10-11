// Delivery address. Firestore: users/{uid}/addresses/{addressId}
class Address {
  final String id;
  final String label; // Home, Office
  final String name;
  final String phone;
  final String street;
  final String city;

  Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
  });

  // Ek line me pata (list me dikhane ke liye)
  String get full => '$street, $city';

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      label: map['label'] ?? 'Home',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'name': name,
        'phone': phone,
        'street': street,
        'city': city,
      };
}
