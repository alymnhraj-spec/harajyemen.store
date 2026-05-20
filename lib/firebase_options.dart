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
        throw UnsupportedError('iOS is not configured yet.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5RSQ2Z3rVJt3cwPrXI34muFh1d6HMG1w',
    appId: '1:119432231710:web:20186535e0be5c61cf270f',
    messagingSenderId: '119432231710',
    projectId: 'haraj-yemen-app',
    authDomain: 'haraj-yemen-app.firebaseapp.com',
    storageBucket: 'haraj-yemen-app.firebasestorage.app',
    measurementId: 'G-8R25CT450B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-sewe1IELCm9uQER-xX-RxHal4PKNZjY',
    appId: '1:119432231710:android:3fd7b6533d7ffa73cf270f',
    messagingSenderId: '119432231710',
    projectId: 'haraj-yemen-app',
    storageBucket: 'haraj-yemen-app.firebasestorage.app',
  );
}
