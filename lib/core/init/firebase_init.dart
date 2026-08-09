import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';

/// Background message handler — must be a top-level function.
/// Called when a push arrives while the app is terminated/background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp is needed here because background isolates
  // don't share the main isolate's initialized state.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Message is delivered to the system tray automatically on Android.
  // Add analytics logging or local DB writes here if needed.
}

Future<void> initializeFirebaseServices() async {
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);

    // Offline persistence configuration
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // 100 MB cache
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
