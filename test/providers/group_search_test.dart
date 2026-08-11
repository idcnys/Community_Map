import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cmap/providers/group_providers.dart';

void main() {
  group('GroupSearchNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial query is empty string', () {
      expect(container.read(groupSearchQueryProvider), '');
    });

    test('setQuery updates state', () {
      container.read(groupSearchQueryProvider.notifier).setQuery('flutter');
      expect(container.read(groupSearchQueryProvider), 'flutter');
    });

    test('setQuery to empty resets', () {
      container.read(groupSearchQueryProvider.notifier).setQuery('test');
      container.read(groupSearchQueryProvider.notifier).setQuery('');
      expect(container.read(groupSearchQueryProvider), '');
    });

    test('setQuery with special characters', () {
      container.read(groupSearchQueryProvider.notifier).setQuery('group@#\$%');
      expect(container.read(groupSearchQueryProvider), 'group@#\$%');
    });
  });
}
