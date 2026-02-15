// Mobile-specific implementations for platform-agnostic functionality
import 'dart:async';
import 'dart:typed_data';

/// No-op implementation for mobile platforms
void revokeObjectUrl(String url) {
  // No-op on mobile platforms
}

/// Returns null for mobile platforms
dynamic createHttpRequest() {
  return null;
}

/// No-op implementation for mobile platforms
Future<Uint8List?> readFileAsBytes(dynamic file) async {
  return null;
}

/// No-op implementation for mobile platforms
Future<List<dynamic>?> pickFilesWithInput(
    {bool multiple = false, String accept = 'image/*'}) async {
  return null;
}
