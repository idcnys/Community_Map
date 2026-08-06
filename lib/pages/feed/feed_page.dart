import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/feed_providers.dart';
import '../../providers/service_providers.dart';
import '../../models/group_model.dart';
import '../../widgets/community_post_card.dart';
import 'notification_panel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _scrollController = ScrollController();
  final Set<String> _viewedPostIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Trigger loadMore when user scrolls near the bottom.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(paginatedFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadCountProvider).value ?? 0;
    final filter = ref.watch(feedFilterProvider);
    final myGroups = ref.watch(myJoinedGroupsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const NotificationPanel(),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildGroupFilter(filter, myGroups),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/create-post'),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Post'),
      ),
      body: _buildFeedList(),
    );
  }

  Widget _buildGroupFilter(String filter, List<GroupModel> myGroups) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip('All', 'all', filter),
          _filterChip('Public', 'public', filter),
          ...myGroups.map((g) => _filterChip(g.name, g.id, filter)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        backgroundColor: isDark
            ? const Color(0xFF1C1C1F)
            : const Color(0xFFF9FAFB),
        selectedColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7)),
          width: 1,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onSelected: (_) {
          ref.read(feedFilterProvider.notifier).setFilter(value);
          ref.invalidate(paginatedFeedProvider);
        },
      ),
    );
  }

  Widget _buildFeedList() {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(paginatedFeedProvider);

    return feedAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
            SizedBox(height: 12),
            Text('Failed to load feed', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => ref.read(paginatedFeedProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (feedState) {
        final posts = feedState.posts;

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.newspaper, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
                SizedBox(height: 16),
                Text(
                  'No posts yet.\nBe the first to share something!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(paginatedFeedProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: posts.length + 1, // +1 for loading indicator
            itemBuilder: (ctx, i) {
              // Loading more indicator at the bottom
              if (i == posts.length) {
                return feedState.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const SizedBox.shrink();
              }

              final post = posts[i];

              // Track view via batcher (once per session per post)
              if (!_viewedPostIds.contains(post.id)) {
                _viewedPostIds.add(post.id);
                ref.read(viewCountBatcherProvider).trackView(post.id);
              }

              return CommunityPostCard(
                post: post,
                onCommentTap: () {
                  context.push(
                    '/dashboard/comments/${post.id}?authorId=${post.authorId}',
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
