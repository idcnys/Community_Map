import 'package:flutter_test/flutter_test.dart';
import 'package:cmap/providers/feed_providers.dart';
import 'package:cmap/models/community_post_model.dart';

CommunityPostModel _makePost(String id) => CommunityPostModel(
      id: id,
      authorId: 'author1',
      authorName: 'Test User',
      title: 'Post $id',
      description: 'Description $id',
      originType: 'public',
      createdAt: DateTime(2025, 1, 1),
    );

void main() {
  group('PaginatedFeedState', () {
    test('default state is empty with hasMore true', () {
      const state = PaginatedFeedState();
      expect(state.posts, isEmpty);
      expect(state.cursor, isNull);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith updates posts', () {
      const state = PaginatedFeedState();
      final posts = [_makePost('1'), _makePost('2')];
      final updated = state.copyWith(posts: posts);

      expect(updated.posts.length, 2);
      expect(updated.hasMore, isTrue); // unchanged
    });

    test('copyWith updates hasMore to false', () {
      const state = PaginatedFeedState();
      final updated = state.copyWith(hasMore: false);

      expect(updated.hasMore, isFalse);
      expect(updated.posts, isEmpty); // unchanged
    });

    test('copyWith sets loadingMore', () {
      const state = PaginatedFeedState();
      final loading = state.copyWith(isLoadingMore: true);
      expect(loading.isLoadingMore, isTrue);

      final done = loading.copyWith(isLoadingMore: false);
      expect(done.isLoadingMore, isFalse);
    });

    test('copyWith clears error when null passed', () {
      final withError = PaginatedFeedState(error: 'Something failed');
      expect(withError.error, 'Something failed');

      final cleared = withError.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith preserves posts when not specified', () {
      final posts = [_makePost('1'), _makePost('2'), _makePost('3')];
      final state = PaginatedFeedState(posts: posts, hasMore: true);

      final updated = state.copyWith(isLoadingMore: true);
      expect(updated.posts.length, 3);
      expect(updated.posts[0].id, '1');
    });

    test('prepend new posts to existing list', () {
      final existing = [_makePost('1'), _makePost('2')];
      final state = PaginatedFeedState(posts: existing);

      final newPost = _makePost('0');
      final updated = state.copyWith(posts: [newPost, ...state.posts]);

      expect(updated.posts.length, 3);
      expect(updated.posts[0].id, '0');
      expect(updated.posts[1].id, '1');
    });

    test('remove post by filtering', () {
      final posts = [_makePost('1'), _makePost('2'), _makePost('3')];
      final state = PaginatedFeedState(posts: posts);

      final updated = state.copyWith(
        posts: state.posts.where((p) => p.id != '2').toList(),
      );

      expect(updated.posts.length, 2);
      expect(updated.posts.map((p) => p.id), ['1', '3']);
    });
  });
}
