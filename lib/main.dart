import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';

import 'core/init/firebase_init.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash visible until ready
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await initializeFirebaseServices();

  // Load environment variables
  await AppConfig.load();

  // Initialize Supabase (for audio storage)
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );

  // Remove native splash — Flutter page takes over
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupForegroundNotifications();
    _setupNotificationTapHandling();
  }

  /// Show a snackbar when a push arrives while app is in foreground.
  void _setupForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      // Show in-app banner via snackbar
      final context = _navigatorKey.currentContext;
      if (context == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null)
                Text(notification.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  /// Navigate when user taps a notification (app in background/terminated).
  void _setupNotificationTapHandling() {
    // App opened from a notification tap (background state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message);
    });

    // App launched directly from a notification tap (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    // Mention notifications carry groupId instead of postId
    final groupId = data['groupId'] as String?;
    final postId = data['postId'] as String?;

    final context = _navigatorKey.currentContext;
    if (context == null) return;

    // Small delay to ensure router is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (type == 'mention' && groupId != null && groupId.isNotEmpty) {
        router.go('/dashboard/group/$groupId');
      } else if (postId != null && postId.isNotEmpty) {
        router.go('/dashboard/comments/$postId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Community App',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.buildTheme(Brightness.light),
      darkTheme: AppTheme.buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarColor: isDark
                ? Colors.black
                : const Color(0xFFFFFFFF),
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return child!;
      },
    );
  }
}
