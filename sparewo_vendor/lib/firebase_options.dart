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
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwC4-PqJ3CPQq2x1DUUET6_qcDmIQD25s',
    appId: '1:900028469691:web:20ddb4a69320740517b49e',
    messagingSenderId: '900028469691',
    projectId: 'sparewovendor',
    storageBucket: 'sparewovendor.firebasestorage.app',
    authDomain: 'sparewovendor.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwC4-PqJ3CPQq2x1DUUET6_qcDmIQD25s',
    appId: '1:900028469691:android:20ddb4a69320740517b49e',
    messagingSenderId: '900028469691',
    projectId: 'sparewovendor',
    storageBucket: 'sparewovendor.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwC4-PqJ3CPQq2x1DUUET6_qcDmIQD25s',
    appId: '1:900028469691:ios:20ddb4a69320740517b49e',
    messagingSenderId: '900028469691',
    projectId: 'sparewovendor',
    storageBucket: 'sparewovendor.firebasestorage.app',
    iosBundleId: 'com.sparewo.vendor',
  );
}
