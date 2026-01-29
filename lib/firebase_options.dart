// File generated manually for Firebase configuration.
// Project: anama-app

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWLqSeJ18WFbZO3vELUdSlhGxUEwOV54E',
    appId: '1:129853756950:android:6dd24dfbf77a895b670737',
    messagingSenderId: '129853756950',
    projectId: 'anama-app',
    storageBucket: 'anama-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAWva0w_50GVcs5GPOYn5d53rN1LlhlDvo',
    appId: '1:129853756950:ios:34c3db0e75ba1d06670737',
    messagingSenderId: '129853756950',
    projectId: 'anama-app',
    storageBucket: 'anama-app.firebasestorage.app',
    iosBundleId: 'com.anama.anama',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWLqSeJ18WFbZO3vELUdSlhGxUEwOV54E',
    appId: '1:129853756950:web:anama670737',
    messagingSenderId: '129853756950',
    projectId: 'anama-app',
    authDomain: 'anama-app.firebaseapp.com',
    storageBucket: 'anama-app.firebasestorage.app',
  );
}

