// lib/core/notifications/fcm_background_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to use other services here (like Firestore),
  // you might need to call Firebase.initializeApp() if it hasn't been called yet.
  // However, on iOS, the background isolate usually inherits the main isolate's Firebase app.

  if (kDebugMode) {
    AppLogger.info(
      'FCMBackgroundHandler',
      'Handling background FCM message',
      extra: {
        'messageId': message.messageId,
        'dataKeys': message.data.keys.toList(),
      },
    );
  }

  // Custom logic for background messages can go here
}
