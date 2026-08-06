import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_post_model.dart';
import '../models/group_model.dart';
import '../models/notification_model.dart';
import '../services/community_post_service.dart';
import 'service_providers.dart';

/// User's group IDs — cached, shared across feed and reports.
final myGroupIdsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(userGroupServiceProvider);
  return service.getMyGroupIds();
});

/// User's joined groups for filter chips.
final myJoinedGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final service = ref.watch(groupServiceProvider);
  return service.getMyJoinedGroups();
});

/// Selected group filter: 'all', 'public', or a groupId.
final feedFilterProvider = NotifierProvider<FeedFilterNotifier, String>(
  FeedFilterNotifier.new,
);

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
  @override
  Future<PaginatedFeedState> build() async {
    return _loadFirstPage();
  }

  Future<PaginatedFeedState> _loadFirstPage() async {
    try {
      final service = ref.read(communityPostServiceProvider);
      final filter = ref.watch(feedFilterProvider);
      final myGroupIdsAsync = ref.watch(myGroupIdsProvider);
      final myGroupIds = myGroupIdsAsync.value ?? [];

      final result = await _fetchPage(service, filter, myGroupIds, null);

      return PaginatedFeedState(
        posts: result.items,
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
      final service = ref.read(communityPostServiceProvider);
      final filter = ref.read(feedFilterProvider);
      final myGroupIds = ref.read(myGroupIdsProvider).value ?? [];

      final result = await _fetchPage(service, filter, myGroupIds, current.cursor);

      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...result.items],
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
    CommunityPostService service,
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
  final service = ref.watch(communityPostServiceProvider);
  return service.getUnreadCount();
});

/// Notification list.
final notificationsProvider = StreamProvider<List<AppNotificationModel>>((ref) {
  final service = ref.watch(communityPostServiceProvider);
  return service.getMyNotifications();
});

/// Comments for a specific post.
final commentsProvider = StreamProvider.family<List<CommunityCommentModel>, String>((ref, postId) {
  final service = ref.watch(communityPostServiceProvider);
  return service.getComments(postId);
});

/// Single post by ID.
final postByIdProvider = StreamProvider.family<CommunityPostModel?, String>((ref, postId) {
  final service = ref.watch(communityPostServiceProvider);
  return service.getPostById(postId);
});
