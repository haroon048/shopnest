// Firestore ke 'users' collection ka model.
// Har user ka ek document hoga: users/{uid}
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String role; // 'admin' ya 'customer'
  final List<String> addresses; // saved delivery addresses
  final List<String> fcmTokens; // push notifications ke liye

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.role = 'customer', // naya user hamesha customer
    required this.addresses,
    required this.fcmTokens,
  });

  // Firestore se aane wala Map -> AppUser
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'customer',
      addresses: List<String>.from(map['addresses'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
    );
  }

  // AppUser -> Map (Firestore me save karne ke liye)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'addresses': addresses,
      'fcmTokens': fcmTokens,
    };
  }
}
