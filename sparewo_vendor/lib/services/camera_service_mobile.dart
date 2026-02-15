// lib/services/camera_service_mobile.dart
import 'dart:typed_data';

Future<String?> takePhotoWeb(
    String? vendorId, String? productId, dynamic service) async {
  // On mobile, this should not be called
  throw UnsupportedError('Web camera not supported on mobile');
}
