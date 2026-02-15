// Platform-agnostic helpers that work on both web and mobile
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// We're using separate web and mobile implementation files
// IMPORTANT: Don't create circular imports with camera_service.dart
import 'web_helpers.dart' if (dart.library.io) 'mobile_helpers.dart' as helpers;

/// Revokes an object URL to prevent memory leaks
/// No-op on mobile platforms
void revokeObjectUrl(String url) {
  if (kIsWeb) {
    helpers.revokeObjectUrl(url);
  }
}

/// Creates an HTTP request object
/// Returns an HttpRequest on web, null on mobile
dynamic createHttpRequest() {
  if (kIsWeb) {
    return helpers.createHttpRequest();
  }
  return null;
}

/// Reads a file as bytes
/// Works with web File objects, returns null on mobile
Future<Uint8List?> readFileAsBytes(dynamic file) async {
  if (kIsWeb) {
    return helpers.readFileAsBytes(file);
  }
  return null;
}

/// Creates a file input element and returns selected files
/// Web-only function, returns null on mobile
Future<List<dynamic>?> pickFilesWithInput(
    {bool multiple = false, String accept = 'image/*'}) async {
  if (kIsWeb) {
    return helpers.pickFilesWithInput(multiple: multiple, accept: accept);
  }
  return null;
}

/// Read blob data as bytes (web-specific)
/// Returns null on mobile platforms
Future<Uint8List?> readBlobData(String blobUrl) async {
  if (kIsWeb) {
    return helpers.readBlobData(blobUrl);
  }
  return null;
}

/// Check if the platform is web
bool get isWebPlatform => kIsWeb;
