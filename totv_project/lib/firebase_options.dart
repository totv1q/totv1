// lib/firebase_options.dart
// أنشئ بـ: flutterfire configure --project=totvq-8e439

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      case TargetPlatform.windows: return web;
      default: return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId:             '1:000000000000:web:000000000000',
    messagingSenderId: '000000000000',
    projectId:         'totvq-8e439',
    authDomain:        'totvq-8e439.firebaseapp.com',
    storageBucket:     'totvq-8e439.firebasestorage.app',
    measurementId:     'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId:             '1:000000000000:android:000000000000',
    messagingSenderId: '000000000000',
    projectId:         'totvq-8e439',
    storageBucket:     'totvq-8e439.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId:             '1:000000000000:ios:000000000000',
    messagingSenderId: '000000000000',
    projectId:         'totvq-8e439',
    storageBucket:     'totvq-8e439.firebasestorage.app',
    iosBundleId:       'com.totv.plus',
  );
}
