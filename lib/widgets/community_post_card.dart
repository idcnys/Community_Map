
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/time_ago.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';
import '../providers/service_providers.dart';

/// Provider that checks if the current user liked a specific post.
final hasLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final service = ref.read(communityPostServiceProvider);
  return service.hasLiked(postId);
});

class CommunityPostCard extends ConsumerStatefulWidget {
  final CommunityPostModel post;
  final VoidCallback? onCommentTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onCommentTap,
  });

  @override
  ConsumerState<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends ConsumerState<CommunityPostCard> {
  bool _isLiked = false;
  bool _loadingLike = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    try {
      final service = ref.read(communityPostServiceProvider);
      final liked = await service.hasLiked(widget.post.id);
      if (mounted) setState(() => _isLiked = liked);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwn =
        widget.post.authorId == FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost indicator
            if (widget.post.isRepost)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.repeat, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.authorName} reposted from ${widget.post.originalAuthorName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            // Header: author + group tag
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        timeAgo(widget.post.createdAt ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.post.isPublic)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.post.groupName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              widget.post.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(
              widget.post.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions row
            Row(
              children: [
                _actionButton(
                  icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  count: widget.post.likeCount,
                  color: _isLiked ? theme.colorScheme.primary : Colors.grey.shade600,
                  onTap: _loadingLike ? null : _toggleLike,
                ),
                _actionButton(
                  icon: Icons.comment_outlined,
                  count: widget.post.commentCount,
                  color: Colors.grey.shade600,
                  onTap: widget.onCommentTap,
                ),
                _actionButton(
                  icon: Icons.repeat,
                  count: widget.post.repostCount,
                  color: widget.post.isRepost ? Colors.grey.shade300 : Colors.grey.shade600,
                  onTap: (isOwn || widget.post.isRepost) ? null : _repost,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.viewCount}',
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    setState(() => _loadingLike = true);
    final service = ref.read(communityPostServiceProvider);
    await service.toggleLike(widget.post.id, widget.post.authorId);
    setState(() {
      _isLiked = !_isLiked;
      _loadingLike = false;
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(communityPostServiceProvider);
              await service.deletePost(widget.post.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _repost() async {
    final groupService = ref.read(groupServiceProvider);
    final groups = await groupService.getMyJoinedGroups().first;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Repost to...',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Public'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final service = ref.read(communityPostServiceProvider);
                  await service.repost(widget.post.id);
                },
              ),
              ...groups.map((g) => ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(g.name),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final service = ref.read(communityPostServiceProvider);
                      await service.repost(
                        widget.post.id,
                        originType: 'group',
                        groupId: g.id,
                        groupName: g.name,
                      );
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
