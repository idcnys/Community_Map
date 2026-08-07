import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      // Primary
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: isDark ? AppColors.darkPrimaryFg : AppColors.lightPrimaryFg,
      primaryContainer: isDark
          ? AppColors.darkSecondary
          : AppColors.lightSecondary,
      onPrimaryContainer: isDark
          ? AppColors.darkSecondaryFg
          : AppColors.lightSecondaryFg,
      // Secondary
      secondary: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
      onSecondary: isDark
          ? AppColors.darkSecondaryFg
          : AppColors.lightSecondaryFg,
      secondaryContainer: isDark
          ? AppColors.darkSecondary
          : AppColors.lightSecondary,
      onSecondaryContainer: isDark
          ? AppColors.darkSecondaryFg
          : AppColors.lightSecondaryFg,
      // Tertiary
      tertiary: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8),
      onTertiary: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B),
      tertiaryContainer: isDark
          ? const Color(0xFF27272A)
          : const Color(0xFFF4F4F5),
      onTertiaryContainer: isDark
          ? const Color(0xFFD4D4D8)
          : const Color(0xFF3F3F46),
      // Surface
      surface: isDark ? AppColors.darkBg : AppColors.lightBg,
      onSurface: isDark ? AppColors.darkFg : AppColors.lightFg,
      surfaceContainerHighest: isDark
          ? AppColors.darkMuted
          : AppColors.lightMuted,
      onSurfaceVariant: isDark ? AppColors.darkMutedFg : AppColors.lightMutedFg,
      surfaceTint: Colors.transparent,
      // Error
      error: isDark ? AppColors.darkDestructive : AppColors.lightDestructive,
      onError: const Color(0xFFFFFFFF),
      errorContainer: isDark
          ? const Color(0xFF450A0A)
          : const Color(0xFFFEE2E2),
      onErrorContainer: isDark
          ? const Color(0xFFFECACA)
          : const Color(0xFF991B1B),
      // Outline / borders
      outline: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
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
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondary,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 1),
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
}
