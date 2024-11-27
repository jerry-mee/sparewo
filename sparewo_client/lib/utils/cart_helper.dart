class CartHelper {
  static double parsePrice(dynamic price) {
    if (price == null) return 0.0;

    if (price is num) {
      return price.toDouble();
    }

    if (price is String) {
      return double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }

    return 0.0;
  }

  static int parseQuantity(dynamic quantity) {
    if (quantity == null) return 1;

    if (quantity is int) {
      return quantity;
    }

    if (quantity is String) {
      return int.tryParse(quantity) ?? 1;
    }

    if (quantity is double) {
      return quantity.toInt();
    }

    return 1;
  }

  static String formatPrice(double price) {
    return 'UGX ${price.toStringAsFixed(2)}';
  }

  static bool isValidPrice(dynamic price) {
    final parsedPrice = parsePrice(price);
    return parsedPrice > 0 && parsedPrice.isFinite;
  }

  static bool isValidQuantity(dynamic quantity) {
    final parsedQuantity = parseQuantity(quantity);
    return parsedQuantity > 0 && parsedQuantity <= 9999;
  }
}
