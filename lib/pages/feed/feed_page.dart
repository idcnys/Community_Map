
import 'package:flutter/material.dart';
import '../../services/community_post_service.dart';
import '../../services/group_service.dart';
import '../../models/community_post_model.dart';
import '../../models/group_model.dart';
import '../../widgets/community_post_card.dart';
import 'notification_panel.dart';
import 'community_post_form.dart';
import 'comments_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _postService = CommunityPostService();
  final _groupService = GroupService();
  final Set<String> _viewedPostIds = {};
  List<String> _myGroupIds = [];
  String _selectedGroupFilter = 'all'; // 'all', 'public', or a groupId
  List<GroupModel> _myGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ids = await _postService.getMyGroupIds();
      if (mounted) setState(() => _myGroupIds = ids);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          // Notification bell
          StreamBuilder<int>(
            stream: _postService.getUnreadCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const NotificationPanel(),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildGroupFilter(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (_) => CommunityPostForm(myGroups: _myGroups)))
              .then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: _buildFeedList(),
    );
  }

  // ─── GROUP FILTER CHIPS ──────────────────────────────────────────
  Widget _buildGroupFilter() {
    return StreamBuilder<List<GroupModel>>(
      stream: _groupService.getMyJoinedGroups(),
      builder: (context, snapshot) {
        _myGroups = snapshot.data ?? [];
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filterChip('All', 'all'),
              _filterChip('Public', 'public'),
              ..._myGroups.map((g) => _filterChip(g.name, g.id)),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedGroupFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedGroupFilter = value);
        },
      ),
    );
  }

  // ─── FEED LIST ───────────────────────────────────────────────────
  Widget _buildFeedList() {
    Stream<List<CommunityPostModel>> stream;

    if (_selectedGroupFilter == 'all') {
      stream = _postService.getFeed(_myGroupIds);
    } else if (_selectedGroupFilter == 'public') {
      stream = _postService.getPublicFeed();
    } else {
      stream = _postService.getFeedByGroup(_selectedGroupFilter);
    }

    return StreamBuilder<List<CommunityPostModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No posts yet.\nBe the first to share something!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _loadData(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: posts.length,
            itemBuilder: (ctx, i) {
              final post = posts[i];
              // Track view: increment once per post per session
              if (!_viewedPostIds.contains(post.id)) {
                _viewedPostIds.add(post.id);
                _postService.incrementView(post.id);
              }
              return CommunityPostCard(
                post: post,
                onCommentTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CommentsPage(
                      postId: post.id,
                      postAuthorId: post.authorId,
                    ),
                  ));
                },
              );
            },
          ),
        );
      },
    );
  }
}
