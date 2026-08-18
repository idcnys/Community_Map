import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_post_model.dart';
import '../models/notification_model.dart';
import '../services/post_service.dart';
import 'service_providers.dart';
import 'guest_provider.dart';

/// User's group IDs — cached, shared across feed and reports.
final myGroupIdsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(userGroupServiceProvider);
  return service.getMyGroupIds();
});

/// Selected group filter: 'all', 'public', or a groupId.
final feedFilterProvider = NotifierProvider<FeedFilterNotifier, String>(
  FeedFilterNotifier.new,
);

/// Set of post IDs the current user has reported.
/// Used to hide reported posts from the feed client-side.
final reportedPostsProvider = NotifierProvider<ReportedPostsNotifier, Set<String>>(
  ReportedPostsNotifier.new,
);

class ReportedPostsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String postId) => state = {...state, postId};
}

class FeedFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) => state = value;
}

// ─── PAGINATED FEED STATE ────────────────────────────────────────────

/// Immutable state for the paginated feed.
class PaginatedFeedState {
  final List<CommunityPostModel> posts;
  final DocumentSnapshot? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const PaginatedFeedState({
    this.posts = const [],
    this.cursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  PaginatedFeedState copyWith({
    List<CommunityPostModel>? posts,
    DocumentSnapshot? cursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) {
    return PaginatedFeedState(
      posts: posts ?? this.posts,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// AsyncNotifier that manages cursor-based paginated feed.
final paginatedFeedProvider =
    AsyncNotifierProvider<PaginatedFeedNotifier, PaginatedFeedState>(
  PaginatedFeedNotifier.new,
);

class PaginatedFeedNotifier extends AsyncNotifier<PaginatedFeedState> {
  StreamSubscription<List<CommunityPostModel>>? _newPostsSub;
  DateTime? _loadedAt;

  @override
  Future<PaginatedFeedState> build() async {
    ref.onDispose(() => _newPostsSub?.cancel());
    final result = await _loadFirstPage();
    _loadedAt = DateTime.now();
    _listenForNewPosts();
    return result;
  }

  /// Subscribe to Firestore for posts created after initial load.
  /// New posts are prepended to the current list (deduplicated).
  void _listenForNewPosts() {
    _newPostsSub?.cancel();
    final service = ref.read(postServiceProvider);
    final isGuest = ref.read(isGuestProvider);
    final filter = isGuest ? 'public' : ref.read(feedFilterProvider);
    final myGroupIds = ref.read(myGroupIdsProvider).value ?? [];

    _newPostsSub = service
        .streamNewPosts(filter: filter, myGroupIds: myGroupIds, since: _loadedAt!)
        .listen((newPosts) {
      final current = state.value;
      if (current == null || newPosts.isEmpty) return;

      final existingIds = current.posts.map((p) => p.id).toSet();
      final fresh = newPosts.where((p) => !existingIds.contains(p.id)).toList();
      if (fresh.isEmpty) return;

      state = AsyncData(current.copyWith(posts: [...fresh, ...current.posts]));
    });
  }

  /// Remove a post locally after deletion (no full reload needed).
  void removePost(String postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      posts: current.posts.where((p) => p.id != postId).toList(),
    ));
  }

  Future<PaginatedFeedState> _loadFirstPage() async {
    try {
      final service = ref.read(postServiceProvider);
      final isGuest = ref.read(isGuestProvider);
      final filter = isGuest ? 'public' : ref.watch(feedFilterProvider);
      final myGroupIdsAsync = ref.watch(myGroupIdsProvider);
      final myGroupIds = myGroupIdsAsync.value ?? [];

      final result = await _fetchPage(service, filter, myGroupIds, null);
      final reportedIds = ref.read(reportedPostsProvider);

      return PaginatedFeedState(
        posts: result.items.where((p) => !reportedIds.contains(p.id)).toList(),
        cursor: result.lastDoc,
        hasMore: result.hasMore,
      );
    } catch (e) {
      // Return empty state with error instead of hanging
      return PaginatedFeedState(
        posts: [],
        hasMore: false,
        error: e.toString(),
      );
    }
  }

  /// Load the next page and append to existing posts.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, error: null));

    try {
      final service = ref.read(postServiceProvider);
      final isGuest = ref.read(isGuestProvider);
      final filter = isGuest ? 'public' : ref.read(feedFilterProvider);
      final myGroupIds = ref.read(myGroupIdsProvider).value ?? [];

      final result = await _fetchPage(service, filter, myGroupIds, current.cursor);

      final reportedIds = ref.read(reportedPostsProvider);
      final filteredItems = result.items.where((p) => !reportedIds.contains(p.id)).toList();

      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...filteredItems],
        cursor: result.lastDoc,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: '$e'));
    }
  }

  /// Refresh: reset to first page.
  Future<void> refresh() async {
    ref.invalidate(myGroupIdsProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFirstPage());
  }

  Future<PaginatedResult<CommunityPostModel>> _fetchPage(
    PostService service,
    String filter,
    List<String> myGroupIds,
    DocumentSnapshot? cursor,
  ) {
    if (filter == 'public') {
      return service.getPublicFeedPage(startAfter: cursor);
    } else if (filter == 'all') {
      return service.getAllFeedPage(myGroupIds, publicCursor: cursor);
    } else {
      return service.getGroupFeedPage(filter, startAfter: cursor);
    }
  }
}

// ─── NOTIFICATIONS ───────────────────────────────────────────────────

/// Unread notification count for the bell badge.
final unreadCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCount();
});

/// Notification list.
final notificationsProvider = StreamProvider<List<AppNotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.getMyNotifications();
});

/// Comments for a specific post.
final commentsProvider = StreamProvider.family<List<CommunityCommentModel>, String>((ref, postId) {
  final service = ref.watch(postServiceProvider);
  return service.getComments(postId);
});

/// Single post by ID.
final postByIdProvider = StreamProvider.family<CommunityPostModel?, String>((ref, postId) {
  final service = ref.watch(postServiceProvider);
  return service.getPostById(postId);
});
