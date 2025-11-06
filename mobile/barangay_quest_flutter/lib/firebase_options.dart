// Firebase configuration for Web and Android.
// iOS remains to be added when building on macOS or after generating via FlutterFire.

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
        throw UnsupportedError(
          'FirebaseOptions for iOS not configured yet. Generate via `flutterfire configure` on macOS.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseOptions not configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration (provided by you).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGioHwNVgUk4ezNxFhCIXhI1xRxKQyjqo',
    appId: '1:15772392583:web:7fd865b5f778cead2cec22',
    messagingSenderId: '15772392583',
    projectId: 'barangay-quest-mobile',
    authDomain: 'barangay-quest-mobile.firebaseapp.com',
    storageBucket: 'barangay-quest-mobile.firebasestorage.app',
    measurementId: 'G-4BEPYF489B',
  );

  // Android configuration (from generated google-services.json / Firebase Console).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCv7BDHvfWBjl2Q3lztprHlMxWp6TI-tc8',
    appId: '1:15772392583:android:0db20735088f3ee92cec22',
    messagingSenderId: '15772392583',
    projectId: 'barangay-quest-mobile',
    storageBucket: 'barangay-quest-mobile.firebasestorage.app',
  );
}
