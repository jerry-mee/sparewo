// lib/services/camera_service.dart
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

import '../exceptions/api_exceptions.dart';
import '../services/logger_service.dart';

// Conditional imports
import 'camera_service_stub.dart'
    if (dart.library.html) 'camera_service_web.dart'
    if (dart.library.io) 'camera_service_mobile.dart' as platform;

class CameraService {
  final FirebaseStorage _storage;
  final LoggerService _logger = LoggerService.instance;
  static const int maxImagesPerProduct = 5;
  static const int maxImageSizeBytes = 5242880; // 5MB = 5 * 1024 * 1024 bytes

  static final ImagePicker _picker = ImagePicker();
  static bool _isPickerActive = false;

  CameraService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // Initialize and check permissions on app start
  Future<void> initializePermissions() async {
    if (!kIsWeb) {
      await checkAndRequestCameraPermission();
      await checkAndRequestGalleryPermission();
    }
  }

  // Check and request camera permission
  Future<bool> checkAndRequestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  // Check and request gallery permission
  Future<bool> checkAndRequestGalleryPermission() async {
    if (kIsWeb) return true;

    PermissionStatus status;
    if (Platform.isAndroid) {
      // Android 13+ uses photos permission
      if (await Permission.photos.status.isGranted) {
        return true;
      }
      status = await Permission.photos.request();
    } else {
      // iOS uses photos permission
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  Future<String> uploadProductImage({
    required String filePath,
    String? vendorId,
    String? productId,
  }) async {
    try {
      final actualVendorId = vendorId ?? FirebaseAuth.instance.currentUser?.uid;
      if (actualVendorId == null || actualVendorId.isEmpty) {
        throw const ApiException(
          message: 'Vendor ID is required for image upload',
          statusCode: 401,
        );
      }

      final fileName =
          '${productId ?? const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          _storage.ref().child('vendors/$actualVendorId/products/$fileName');

      if (kIsWeb) {
        _logger
            .info('Web upload not implemented - use uploadImageData instead');
        throw const ApiException(
          message: 'Use uploadImageData for web uploads',
          statusCode: 501,
        );
      } else {
        return await _uploadMobileImage(filePath, ref);
      }
    } catch (e) {
      _logger.error('Error uploading image', error: e);
      throw ApiException(
        message: 'Failed to upload image: ${e.toString()}',
        statusCode: e is ApiException ? e.statusCode : 500,
      );
    }
  }

  Future<String> _uploadMobileImage(String filePath, Reference ref) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ApiException(
        message: 'File not found: $filePath',
        statusCode: 400,
      );
    }

    final fileSize = await file.length();
    if (fileSize > maxImageSizeBytes) {
      throw const ApiException(
        message: 'File size exceeds maximum limit of 5MB',
        statusCode: 400,
      );
    }

    final fileExtension =
        path.extension(filePath).replaceAll('.', '').toLowerCase();
    final contentType =
        'image/${fileExtension == 'jpg' ? 'jpeg' : fileExtension}';

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadTimestamp': DateTime.now().toIso8601String(),
        },
      ),
    );

    final downloadUrl = await uploadTask.ref.getDownloadURL();
    _logger.info('Image uploaded successfully: $downloadUrl');
    return downloadUrl;
  }

  Future<String> uploadImageData({
    required Uint8List imageData,
    String? vendorId,
    String? productId,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final actualVendorId = vendorId ?? FirebaseAuth.instance.currentUser?.uid;

      if (actualVendorId == null || actualVendorId.isEmpty) {
        throw const ApiException(
          message: 'Vendor ID is required for image upload',
          statusCode: 401,
        );
      }

      if (imageData.length > maxImageSizeBytes) {
        throw const ApiException(
          message: 'File size exceeds maximum limit of 5MB',
          statusCode: 400,
        );
      }

      final fileName =
          '${productId ?? const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          _storage.ref().child('vendors/$actualVendorId/products/$fileName');

      // Upload data
      final uploadTask = await ref.putData(
        imageData,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'vendorId': actualVendorId,
            'productId': productId ?? 'pending',
            'uploadTimestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      _logger.info('Image data uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.error('Error uploading image data', error: e);
      throw ApiException(
        message: 'Failed to upload image data: ${e.toString()}',
        statusCode: e is ApiException ? e.statusCode : 500,
      );
    }
  }

  Future<String?> takePhoto({
    String? productId,
    String? vendorId,
  }) async {
    if (kIsWeb) {
      // Use web camera for taking photos on web
      return await platform.takePhotoWeb(vendorId, productId, this);
    }

    return await _takePhotoMobile(productId, vendorId);
  }

  Future<String?> _takePhotoMobile(String? productId, String? vendorId) async {
    if (_isPickerActive) {
      _logger.warning('Image picker is already active');
      return null;
    }

    try {
      _isPickerActive = true;
      _logger.info('Attempting to take photo on mobile');

      // Check camera permission
      final hasPermission = await checkAndRequestCameraPermission();
      if (!hasPermission) {
        _logger.error('Camera permission denied');
        throw const ApiException(
          message: 'Camera permission is required to take photos',
          statusCode: 403,
        );
      }

      // Take photo
      XFile? pickedFile;
      for (int retry = 0; retry < 2; retry++) {
        try {
          if (retry > 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }

          pickedFile = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
            maxWidth: 1920,
            maxHeight: 1080,
          );
          break;
        } catch (e) {
          _logger.error('Error picking image, attempt ${retry + 1}', error: e);
          if (retry >= 1) rethrow;
        }
      }

      if (pickedFile == null) {
        _logger.info('No image captured');
        return null;
      }

      // Upload the image
      return await uploadProductImage(
        filePath: pickedFile.path,
        vendorId: vendorId,
        productId: productId,
      );
    } catch (e) {
      _logger.error('Error taking photo on mobile', error: e);
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  Future<List<String>> pickMultipleImages({
    String? vendorId,
    String? productId,
  }) async {
    if (kIsWeb) {
      return await _pickMultipleImagesWeb(vendorId, productId);
    }

    return await _pickMultipleImagesMobile(vendorId, productId);
  }

  Future<List<String>> _pickMultipleImagesWeb(
      String? vendorId, String? productId) async {
    try {
      _logger.info('Picking multiple images on web');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('No images selected');
        return [];
      }

      // Limit to max images per product
      final filesToUpload = result.files.length > maxImagesPerProduct
          ? result.files.sublist(0, maxImagesPerProduct)
          : result.files;

      if (result.files.length > maxImagesPerProduct) {
        _logger.info(
            'Selected ${result.files.length} images, limiting to $maxImagesPerProduct');
      }

      final List<String> uploadedUrls = [];
      for (final file in filesToUpload) {
        if (file.bytes == null) continue;

        try {
          // Check file size
          if (file.size > maxImageSizeBytes) {
            _logger.warning('File ${file.name} exceeds size limit, skipping');
            continue;
          }

          final contentType = _getContentType(file.extension ?? 'jpg');
          final url = await uploadImageData(
            imageData: file.bytes!,
            vendorId: vendorId,
            productId: productId,
            contentType: contentType,
          );
          uploadedUrls.add(url);
        } catch (e) {
          _logger.error('Error uploading image: ${file.name}', error: e);
          // Continue uploading other images even if one fails
        }
      }

      return uploadedUrls;
    } catch (e) {
      _logger.error('Error picking images on web', error: e);
      rethrow;
    }
  }

  Future<List<String>> _pickMultipleImagesMobile(
      String? vendorId, String? productId) async {
    if (_isPickerActive) {
      _logger.warning('Image picker is already active');
      return [];
    }

    try {
      _isPickerActive = true;
      _logger.info('Picking multiple images on mobile');

      // Check gallery permission
      final hasPermission = await checkAndRequestGalleryPermission();
      if (!hasPermission) {
        _logger.error('Gallery permission denied');
        throw const ApiException(
          message: 'Gallery permission is required to select photos',
          statusCode: 403,
        );
      }

      // Pick images
      List<XFile>? pickedFiles;
      for (int retry = 0; retry < 2; retry++) {
        try {
          if (retry > 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }

          pickedFiles = await _picker.pickMultiImage(
            imageQuality: 80,
            maxWidth: 1920,
            maxHeight: 1080,
          );
          break;
        } catch (e) {
          _logger.error('Error picking multiple images, attempt ${retry + 1}',
              error: e);
          if (retry >= 1) rethrow;
        }
      }

      if (pickedFiles == null || pickedFiles.isEmpty) {
        _logger.info('No images selected');
        return [];
      }

      // Limit to max images per product
      final filesToUpload = pickedFiles.length > maxImagesPerProduct
          ? pickedFiles.sublist(0, maxImagesPerProduct)
          : pickedFiles;

      if (pickedFiles.length > maxImagesPerProduct) {
        _logger.info(
            'Selected ${pickedFiles.length} images, limiting to $maxImagesPerProduct');
      }

      // Upload images
      final List<String> uploadedUrls = [];
      for (final file in filesToUpload) {
        try {
          final url = await uploadProductImage(
            filePath: file.path,
            vendorId: vendorId,
            productId: productId,
          );
          uploadedUrls.add(url);
        } catch (e) {
          _logger.error('Error uploading image: ${file.path}', error: e);
          // Continue uploading other images even if one fails
        }
      }

      return uploadedUrls;
    } catch (e) {
      _logger.error('Error picking images on mobile', error: e);
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  Future<String?> pickSingleImage({
    String? vendorId,
    String? productId,
  }) async {
    if (kIsWeb) {
      return await _pickSingleImageWeb(vendorId, productId);
    }

    return await _pickSingleImageMobile(vendorId, productId);
  }

  Future<String?> _pickSingleImageWeb(
      String? vendorId, String? productId) async {
    try {
      _logger.info('Picking single image on web');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _logger.info('No image selected');
        return null;
      }

      final file = result.files.first;
      if (file.bytes == null) {
        _logger.error('File bytes are null');
        return null;
      }

      // Check file size
      if (file.size > maxImageSizeBytes) {
        throw const ApiException(
          message: 'File size exceeds maximum limit of 5MB',
          statusCode: 400,
        );
      }

      final contentType = _getContentType(file.extension ?? 'jpg');
      return await uploadImageData(
        imageData: file.bytes!,
        vendorId: vendorId,
        productId: productId,
        contentType: contentType,
      );
    } catch (e) {
      _logger.error('Error picking single image on web', error: e);
      rethrow;
    }
  }

  Future<String?> _pickSingleImageMobile(
      String? vendorId, String? productId) async {
    if (_isPickerActive) {
      _logger.warning('Image picker is already active');
      return null;
    }

    try {
      _isPickerActive = true;

      // Check gallery permission
      final hasPermission = await checkAndRequestGalleryPermission();
      if (!hasPermission) {
        _logger.error('Gallery permission denied');
        throw const ApiException(
          message: 'Gallery permission is required to select photos',
          statusCode: 403,
        );
      }

      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile == null) {
        _logger.info('No image selected');
        return null;
      }

      // Upload the image
      return await uploadProductImage(
        filePath: pickedFile.path,
        vendorId: vendorId,
        productId: productId,
      );
    } catch (e) {
      _logger.error('Error picking single image', error: e);
      rethrow;
    } finally {
      _isPickerActive = false;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      if (!imageUrl.startsWith('http')) return;

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      _logger.info('Image deleted: $imageUrl');
    } catch (e) {
      _logger.error('Error deleting image', error: e);
      throw ApiException(
        message: 'Failed to delete image: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get remaining image slots for a product
  int getRemainingImageSlots(int currentImageCount) {
    return maxImagesPerProduct - currentImageCount;
  }

  // Validate image count
  bool canAddMoreImages(int currentImageCount) {
    return currentImageCount < maxImagesPerProduct;
  }

  // Helper method to get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
