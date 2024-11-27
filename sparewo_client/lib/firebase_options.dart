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
    appId: '1:858998050859:android:79af5856ed22a972071a6e',
    messagingSenderId: '858998050859',
    projectId: 'sparewoapp',
    storageBucket: 'sparewoapp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwaPqmEV0UPdPPMV351GXPycDvjgoF5UE',
    appId: '1:858998050859:ios:79af5856ed22a972071a6e',
    messagingSenderId: '858998050859',
    projectId: 'sparewoapp',
    storageBucket: 'sparewoapp.appspot.com',
    iosBundleId: 'com.sparewo.client',
  );
}
