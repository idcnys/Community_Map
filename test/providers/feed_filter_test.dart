import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/providers/feed_providers.dart';

void main() {
  group('FeedFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is "all"', () {
      final filter = container.read(feedFilterProvider);
      expect(filter, 'all');
    });

    test('setFilter changes state', () {
      container.read(feedFilterProvider.notifier).setFilter('public');
      expect(container.read(feedFilterProvider), 'public');
    });

    test('setFilter to group ID', () {
      container.read(feedFilterProvider.notifier).setFilter('group123');
      expect(container.read(feedFilterProvider), 'group123');
    });

    test('setFilter back to all', () {
      container.read(feedFilterProvider.notifier).setFilter('public');
      container.read(feedFilterProvider.notifier).setFilter('all');
      expect(container.read(feedFilterProvider), 'all');
    });
  });

  group('PaginatedFeedState', () {
    test('default state', () {
      const state = PaginatedFeedState();

      expect(state.posts, isEmpty);
      expect(state.cursor, isNull);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = PaginatedFeedState();
      final updated = state.copyWith(isLoadingMore: true);

      expect(updated.isLoadingMore, isTrue);
      expect(updated.hasMore, isTrue);
      expect(updated.posts, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      const state = PaginatedFeedState(hasMore: false, isLoadingMore: true);
      final updated = state.copyWith(error: 'Something went wrong');

      expect(updated.hasMore, isFalse);
      expect(updated.isLoadingMore, isTrue);
      expect(updated.error, 'Something went wrong');
    });

    test('copyWith clears error when null is passed', () {
      const state = PaginatedFeedState(error: 'old error');
      final updated = state.copyWith(error: null);

      expect(updated.error, isNull);
    });
  });
}
