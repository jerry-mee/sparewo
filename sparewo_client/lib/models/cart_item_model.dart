class CartItem {
  final String productName;
  final String price; // Kept as String to match API response
  final String quantity;

  CartItem({
    required this.productName,
    required this.price,
    required this.quantity,
  });

  // Add a factory constructor to handle JSON parsing
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productName: json['productName'] as String,
      price: json['price'] as String,
      quantity: json['quantity'] as String,
    );
  }
}
