import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('dark theme is defined', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });

    test('light theme is defined', () {
      final theme = AppTheme.buildTheme(Brightness.light);
      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme uses Material 3', () {
      final theme = AppTheme.buildTheme(Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('textTheme is defined', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme.textTheme, isNotNull);
      expect(theme.textTheme.bodyLarge, isNotNull);
      expect(theme.textTheme.headlineLarge, isNotNull);
    });

    test('colorScheme has primary defined', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme.colorScheme.primary, isNotNull);
      expect(theme.colorScheme.onPrimary, isNotNull);
      expect(theme.colorScheme.error, isNotNull);
    });

    test('inputDecorationTheme is configured', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme.inputDecorationTheme, isNotNull);
    });

    test('elevatedButtonTheme is configured', () {
      final theme = AppTheme.buildTheme(Brightness.dark);
      expect(theme.elevatedButtonTheme, isNotNull);
    });

    test('dark and light themes differ', () {
      final dark = AppTheme.buildTheme(Brightness.dark);
      final light = AppTheme.buildTheme(Brightness.light);
      expect(dark.colorScheme.primary, isNot(light.colorScheme.primary));
    });
  });
}
