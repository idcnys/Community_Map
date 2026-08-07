import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/init/firebase_init.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash visible until ready
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await initializeFirebaseServices();

  // Initialize Supabase (for audio storage)
  await Supabase.initialize(
    url: 'https://nvgvurjuztboepaihbsl.supabase.co',
    publishableKey: 'sb_publishable_04bL7uGgzqdDv-L7sevFEQ_9iDkdptf',
  );

  // Remove native splash — Flutter page takes over
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
