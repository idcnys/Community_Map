
// File generated manually from google-services.json.
// Project: cmap-0

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured. Run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEM3qZMqzOAmSFzCwMt24rxcGydvV20dg',
    appId: '1:505795864357:android:431ad844557410e6db5ccc',
    messagingSenderId: '505795864357',
    projectId: 'cmap-0',
    storageBucket: 'cmap-0.firebasestorage.app',
  );
}
