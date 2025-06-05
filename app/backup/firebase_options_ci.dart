// CI-safe Firebase options with placeholder values
// This file can be safely committed to version control
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// CI-safe [FirebaseOptions] with placeholder values
/// Real Firebase services will not work with these values,
/// but compilation and testing will succeed
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
    apiKey: 'ci-placeholder-web-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bee-mvp-3ab43',
    authDomain: 'bee-mvp-3ab43.firebaseapp.com',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    measurementId: 'G-0000000000',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'ci-placeholder-android-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'ci-placeholder-ios-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    iosBundleId: 'com.momentumhealth.beemvp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'ci-placeholder-macos-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bee-mvp-3ab43',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    iosBundleId: 'com.example.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'ci-placeholder-windows-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'bee-mvp-3ab43',
    authDomain: 'bee-mvp-3ab43.firebaseapp.com',
    storageBucket: 'bee-mvp-3ab43.firebasestorage.app',
    measurementId: 'G-0000000000',
  );
}
