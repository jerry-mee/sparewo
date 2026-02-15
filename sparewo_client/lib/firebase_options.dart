// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwaPqmEV0UPdPPMV351GXPycDvjgoF5UE',
    appId: '1:858998050859:web:79af5856ed22a972071a6e',
    messagingSenderId: '858998050859',
    projectId: 'sparewoapp',
    storageBucket: 'sparewoapp.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwaPqmEV0UPdPPMV351GXPycDvjgoF5UE',
    appId: '1:858998050859:android:5bbf99e694b73574071a6e',
    messagingSenderId: '858998050859',
    projectId: 'sparewoapp',
    storageBucket: 'sparewoapp.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvDsZlTg0s7xTlgeYuGzwKWXZRi0pWVnY',
    appId: '1:858998050859:ios:fe08857b21acf4d8071a6e',
    messagingSenderId: '858998050859',
    projectId: 'sparewoapp',
    storageBucket: 'sparewoapp.firebasestorage.app',
    androidClientId: '858998050859-046une0jqhbpd3r3d1qukurakcdik55b.apps.googleusercontent.com',
    iosClientId: '858998050859-qk2u2ugomvkju1t3cigln9ul5mhki76a.apps.googleusercontent.com',
    iosBundleId: 'com.sparewo.client',
  );

}