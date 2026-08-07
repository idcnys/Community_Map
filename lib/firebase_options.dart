import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) {
      return null; // Web not configured
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null; // Linux, macOS, Windows not configured
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEM3qZMqzOAmSFzCwMt24rxcGydvV20dg',
    appId: '1:505795864357:android:431ad844557410e6db5ccc',
    messagingSenderId: '505795864357',
    projectId: 'cmap-0',
    storageBucket: 'cmap-0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFD1vUndswqDM2ITnVoXK-JUjZEmPI4m4',
    appId: '1:505795864357:ios:f8acc921f1a38f5bdb5ccc',
    messagingSenderId: '505795864357',
    projectId: 'cmap-0',
    storageBucket: 'cmap-0.firebasestorage.app',
    iosBundleId: 'com.communityapp',
  );
}
