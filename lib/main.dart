import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash visible until we're ready
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);

    // ─── Offline persistence configuration ─────────────────────────
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 104857600, // 100 MB cache for offline-first
    );
  }

  // Remove native splash — Flutter splash page takes over
  FlutterNativeSplash.remove();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _DesktopUnsupported(),
    ));
  } else {
    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Community App',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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

  // ─── shadcn-inspired zinc palette ──────────────────────────────────
  static const _zinc = (
    // Light
    lightBg: Color(0xFFFFFFFF),
    lightFg: Color(0xFF09090B),
    lightPrimary: Color(0xFF18181B),
    lightPrimaryFg: Color(0xFFFAFAFA),
    lightSecondary: Color(0xFFF4F4F5),
    lightSecondaryFg: Color(0xFF18181B),
    lightMuted: Color(0xFFF4F4F5),
    lightMutedFg: Color(0xFF71717A),
    lightBorder: Color(0xFFE4E4E7),
    lightDestructive: Color(0xFFEF4444),
    // Dark
    darkBg: Color(0xFF09090B),
    darkFg: Color(0xFFFAFAFA),
    darkPrimary: Color(0xFFFAFAFA),
    darkPrimaryFg: Color(0xFF18181B),
    darkSecondary: Color(0xFF27272A),
    darkSecondaryFg: Color(0xFFFAFAFA),
    darkMuted: Color(0xFF27272A),
    darkMutedFg: Color(0xFFA1A1AA),
    darkBorder: Color(0xFF27272A),
    darkDestructive: Color(0xFFDC2626),
  );

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary
      primary: isDark ? _zinc.darkPrimary : _zinc.lightPrimary,
      onPrimary: isDark ? _zinc.darkPrimaryFg : _zinc.lightPrimaryFg,
      primaryContainer: isDark ? _zinc.darkSecondary : _zinc.lightSecondary,
      onPrimaryContainer: isDark
          ? _zinc.darkSecondaryFg
          : _zinc.lightSecondaryFg,
      // Secondary
      secondary: isDark ? _zinc.darkSecondary : _zinc.lightSecondary,
      onSecondary: isDark ? _zinc.darkSecondaryFg : _zinc.lightSecondaryFg,
      secondaryContainer: isDark ? _zinc.darkSecondary : _zinc.lightSecondary,
      onSecondaryContainer: isDark
          ? _zinc.darkSecondaryFg
          : _zinc.lightSecondaryFg,
      // Tertiary (subtle accent)
      tertiary: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
      onTertiary: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
      tertiaryContainer: isDark
          ? const Color(0xFF27272A)
          : const Color(0xFFF4F4F5),
      onTertiaryContainer: isDark
          ? const Color(0xFFD4D4D8)
          : const Color(0xFF3F3F46),
      // Surface
      surface: isDark ? _zinc.darkBg : _zinc.lightBg,
      onSurface: isDark ? _zinc.darkFg : _zinc.lightFg,
      surfaceContainerHighest: isDark ? _zinc.darkMuted : _zinc.lightMuted,
      onSurfaceVariant: isDark ? _zinc.darkMutedFg : _zinc.lightMutedFg,
      surfaceTint: Colors.transparent,
      // Error
      error: isDark ? _zinc.darkDestructive : _zinc.lightDestructive,
      onError: const Color(0xFFFFFFFF),
      errorContainer: isDark
          ? const Color(0xFF450A0A)
          : const Color(0xFFFEE2E2),
      onErrorContainer: isDark
          ? const Color(0xFFFECACA)
          : const Color(0xFF991B1B),
      // Outline / borders
      outline: isDark ? _zinc.darkBorder : _zinc.lightBorder,
      outlineVariant: isDark
          ? const Color(0xFF3F3F46)
          : const Color(0xFFE4E4E7),
      // Inverse
      inverseSurface: isDark
          ? const Color(0xFFFAFAFA)
          : const Color(0xFF18181B),
      onInverseSurface: isDark
          ? const Color(0xFF18181B)
          : const Color(0xFFFAFAFA),
      inversePrimary: isDark
          ? const Color(0xFF18181B)
          : const Color(0xFFFAFAFA),
      // Scrim & shadow
      scrim: const Color(0xFF000000),
      shadow: const Color(0xFF000000),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(
        isDark
            ? ThemeData(brightness: Brightness.dark).textTheme
            : ThemeData(brightness: Brightness.light).textTheme,
      ),

      // ─── NavigationBar ───
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onSurface);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12);
        }),
      ),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),

      // ─── Input fields ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF18181B) : const Color(0xFFFAFAFA),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // ─── Chips ───
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondary,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ─── Filled Buttons ───
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),

      // ─── Outlined Buttons ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline, width: 1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ─── Text Buttons ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ─── Dialogs ───
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),

      // ─── Scaffold ───
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}


class _DesktopUnsupported extends StatelessWidget {
  const _DesktopUnsupported();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_android, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'CMap',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'This app requires Firebase, which is not available on desktop.\n'
                'Please run on Android or iOS for the full experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Text(
                'Platform: ${Platform.operatingSystem}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
