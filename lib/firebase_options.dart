
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6NMFWdtMM9g4ZkAncGUUO5yeDeB_mjY8',
    appId: '1:838056305267:web:f0272acc681e437a7ec006',
    messagingSenderId: '838056305267',
    projectId: 'alhussain-hosiery',
    authDomain: 'alhussain-hosiery.firebaseapp.com',
    storageBucket: 'alhussain-hosiery.firebasestorage.app',
    measurementId: 'G-JSZYNZ1V21',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5ThsWfcvtylVkH2xQrtcHoul3BrR5sq8',
    appId: '1:838056305267:android:67aeabfd1d8fc7557ec006',
    messagingSenderId: '838056305267',
    projectId: 'alhussain-hosiery',
    storageBucket: 'alhussain-hosiery.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBV0AK-Li3ILbHxgikmwPFdecspYDyrtLo',
    appId: '1:838056305267:ios:6ce5acaa034990dc7ec006',
    messagingSenderId: '838056305267',
    projectId: 'alhussain-hosiery',
    storageBucket: 'alhussain-hosiery.firebasestorage.app',
    iosBundleId: 'com.example.alhussainShop',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBV0AK-Li3ILbHxgikmwPFdecspYDyrtLo',
    appId: '1:838056305267:ios:6ce5acaa034990dc7ec006',
    messagingSenderId: '838056305267',
    projectId: 'alhussain-hosiery',
    storageBucket: 'alhussain-hosiery.firebasestorage.app',
    iosBundleId: 'com.example.alhussainShop',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB6NMFWdtMM9g4ZkAncGUUO5yeDeB_mjY8',
    appId: '1:838056305267:web:fdb9a07679b0f39a7ec006',
    messagingSenderId: '838056305267',
    projectId: 'alhussain-hosiery',
    authDomain: 'alhussain-hosiery.firebaseapp.com',
    storageBucket: 'alhussain-hosiery.firebasestorage.app',
    measurementId: 'G-DZVH3LMFBJ',
  );
}
