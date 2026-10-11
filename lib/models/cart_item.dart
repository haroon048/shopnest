class CartItem {
  final String productId;
  final String name;
  final double price;
  final String image;
  final int qty;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.qty,
  });

  double get total => price * qty;

  factory CartItem.fromMap(Map<String, dynamic> map, String productId) {
    return CartItem(
      productId: productId,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      image: map['image'] as String? ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'image': image,
        'qty': qty,
      };
}
