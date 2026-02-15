// lib/utils/validators.dart

class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // FIX: Renamed 'required' to 'notEmpty' to match usage in the UI files.
  static String? notEmpty(String? value, String field) {
    if (value == null || value.isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // FIX: Fixed the signature of the 'number' validator.
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'A number is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    // Remove commas for validation
    final cleanValue = value.replaceAll(',', '');
    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Please enter a valid price';
    }
    final numValue = int.tryParse(cleanValue);
    if (numValue == null || numValue <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }
}
