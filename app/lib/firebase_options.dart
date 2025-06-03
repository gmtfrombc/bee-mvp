// CI-safe Firebase options with placeholder values
// This file can be safely committed to version control
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// CI-safe [FirebaseOptions] with placeholder values
/// Real Firebase services will not work with these values,
/// but compilation and testing will succeed
///
/// TODO: Replace with real Firebase credentials for production deployment
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
    apiKey: '***REMOVED***',
    appId: '1:1018557691786:web:70a78ca2f3781983fc7a73',
    messagingSenderId: '1018557691786',
    projectId: 'bee-mvp-3ab43',
    authDomain: 'bee-mvp-3ab43.firebaseapp.com',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    measurementId: 'G-RS4YWFKSZB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '***REMOVED***',
    appId: '1:1018557691786:android:848943b6b7cd62fbfc7a73',
    messagingSenderId: '1018557691786',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '***REMOVED***',
    appId: '1:1018557691786:ios:8d4f0b2e9c258e6ffc7a73',
    messagingSenderId: '1018557691786',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    iosBundleId: 'com.momentumhealth.beemvp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '***REMOVED***',
    appId: '1:1018557691786:ios:009ac33b9b194fb3fc7a73',
    messagingSenderId: '1018557691786',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '***REMOVED***',
    appId: '1:1018557691786:web:70a78ca2f3781983fc7a73',
    messagingSenderId: '1018557691786',
    projectId: 'bee-mvp-3ab43',
    authDomain: 'bee-mvp-3ab43.firebaseapp.com',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    measurementId: 'G-RS4YWFKSZB',
  );

}