
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/time_ago.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';
import '../providers/service_providers.dart';
import '../services/post_service.dart';
import '../providers/feed_providers.dart';
import '../providers/guest_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Provider that checks if the current user liked a specific post.
final hasLikedProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final service = ref.read(postServiceProvider);
  return service.hasLiked(postId);
});

class CommunityPostCard extends ConsumerStatefulWidget {
  final CommunityPostModel post;
  final VoidCallback? onCommentTap;
  final VoidCallback? onOriginalPostTap;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onCommentTap,
    this.onOriginalPostTap,
  });

  @override
  ConsumerState<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends ConsumerState<CommunityPostCard> {
  bool _isLiked = false;
  bool _loadingLike = false;
  List<String> _myPollVotes = [];
  bool _loadingVotes = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
    if (widget.post.isPoll) _checkPollVotes();
  }

  Future<void> _checkPollVotes() async {
    try {
      final pollService = ref.read(pollServiceProvider);
      final votes = await pollService.getMyVotes(widget.post.id);
      if (mounted) setState(() => _myPollVotes = votes);
    } catch (e) { debugPrint('[] error: $e'); }
  }

  Future<void> _checkLiked() async {
    try {
      final service = ref.read(postServiceProvider);
      final liked = await service.hasLiked(widget.post.id);
      if (mounted) setState(() => _isLiked = liked);
    } catch (e) { debugPrint('[] error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwn =
        widget.post.authorId == FirebaseAuth.instance.currentUser?.uid;

    // Live post data via shared Riverpod StreamProvider (auto-disposed, deduplicated)
    final livePostAsync = ref.watch(postByIdProvider(widget.post.id));
    final livePost = livePostAsync.value ?? widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost indicator (tappable → original post)
            if (widget.post.isRepost)
              GestureDetector(
                onTap: widget.onOriginalPostTap,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.repeat, size: 14, color: theme.colorScheme.primary),
                      SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            children: [
                              TextSpan(text: '${widget.post.authorName} reposted from '),
                              TextSpan(
                                text: widget.post.originalAuthorName,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Header: author + group tag
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: widget.post.authorImageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(widget.post.authorImageUrl)
                      : null,
                  child: widget.post.authorImageUrl.isEmpty
                      ? Text(
                          widget.post.authorName.isNotEmpty
                              ? widget.post.authorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
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
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.post.isPublic)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.post.groupName,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onTertiaryContainer,
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
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),

            // ─── POST IMAGE ───────────────────────────────────────
            if (widget.post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  width: double.infinity,
                  maxHeightDiskCache: 400,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 100,
                    color: theme.colorScheme.errorContainer,
                    child: Center(
                      child: Icon(LucideIcons.imageOff, color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Poll UI — uses live data
            if (widget.post.isPoll) ...[
              _buildPollUI(theme, livePost),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
            ],
            // Actions row
            Builder(builder: (context) {
              final isGuest = ref.read(isGuestProvider);
              return Row(
                children: [
                  _actionButton(
                    icon: _isLiked ? Icons.thumb_up : LucideIcons.thumbsUp,
                    count: livePost.likeCount,
                    color: _isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    onTap: (isGuest || _loadingLike) ? null : _toggleLike,
                  ),
                  _actionButton(
                    icon: LucideIcons.messageCircle,
                    count: livePost.commentCount,
                    color: theme.colorScheme.onSurfaceVariant,
                    onTap: isGuest ? null : widget.onCommentTap,
                  ),
                  _actionButton(
                    icon: LucideIcons.repeat,
                    count: livePost.repostCount,
                    color: widget.post.isRepost ? theme.colorScheme.outline : theme.colorScheme.onSurfaceVariant,
                    onTap: (isGuest || isOwn || widget.post.isRepost) ? null : _repost,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(LucideIcons.eye, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${livePost.viewCount}',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isOwn && !isGuest)
                    IconButton(
                      icon: Icon(LucideIcons.flag,
                          size: 20, color: theme.colorScheme.onSurfaceVariant),
                      tooltip: 'Report',
                      onPressed: () => _showReportDialog(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (isOwn)
                    IconButton(
                      icon: Icon(LucideIcons.trash2,
                          size: 20, color: theme.colorScheme.error),
                      onPressed: () => _confirmDelete(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _loadingLike = true;
    });
    final service = ref.read(postServiceProvider);
    await service.toggleLike(widget.post.id, widget.post.authorId);
    if (mounted) setState(() => _loadingLike = false);
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
              final service = ref.read(postServiceProvider);
              await service.deletePost(widget.post.id);
              ref.read(paginatedFeedProvider.notifier).removePost(widget.post.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final service = ref.read(postServiceProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        title: Row(
          children: [
            Icon(LucideIcons.flag, color: Theme.of(ctx).colorScheme.error, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('Report Post', style: Theme.of(ctx).textTheme.titleMedium)),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              onPressed: () => Navigator.of(ctx).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting this post?',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...PostService.reportCauses.map((cause) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 4,
              title: Text(cause, style: const TextStyle(fontSize: 13)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final error = await service.reportPost(widget.post.id, cause);
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                } else {
                  // Track reported post so it stays hidden on feed reload
                  ref.read(reportedPostsProvider.notifier).add(widget.post.id);
                  // Remove post from feed immediately for the reporter
                  ref.read(paginatedFeedProvider.notifier).removePost(widget.post.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post reported. It will be hidden from your feed.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPollUI(ThemeData theme, CommunityPostModel post) {
    final totalVotes = post.totalPollVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Poll type badge
        Row(
          children: [
            Icon(
              post.pollType == 'single' ? LucideIcons.circleDot : LucideIcons.checkSquare,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              post.pollType == 'single' ? 'Single choice' : 'Multiple choice',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Options
        ...List.generate(post.pollOptions.length, (i) {
          final key = '$i';
          final voters = post.pollVotes[key] ?? [];
          final voteCount = voters.length;
          final percentage = totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
          final isSelected = _myPollVotes.contains(key);

          final isGuest = ref.read(isGuestProvider);
          return GestureDetector(
            onTap: (isGuest || _loadingVotes) ? null : () => _votePoll(key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(128),
                  width: isSelected ? 1.5 : 1,
                ),
                color: isSelected ? theme.colorScheme.primary.withAlpha(20) : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected
                            ? (post.pollType == 'single' ? Icons.radio_button_checked : Icons.check_box)
                            : (post.pollType == 'single' ? Icons.radio_button_unchecked : Icons.check_box_outline_blank),
                        size: 18,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.pollOptions[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '$voteCount',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (totalVotes > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 5,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _votePoll(String optionKey) async {
    setState(() => _loadingVotes = true);

    List<String> newVotes;
    if (widget.post.pollType == 'single') {
      newVotes = [optionKey];
    } else {
      newVotes = List.from(_myPollVotes);
      if (newVotes.contains(optionKey)) {
        newVotes.remove(optionKey);
      } else {
        newVotes.add(optionKey);
      }
    }

    if (newVotes.isEmpty) {
      setState(() => _loadingVotes = false);
      return;
    }

    final pollService = ref.read(pollServiceProvider);
    await pollService.vote(widget.post.id, newVotes);
    if (mounted) {
      setState(() {
        _myPollVotes = newVotes;
        _loadingVotes = false;
      });
    }
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
                leading: const Icon(LucideIcons.globe),
                title: const Text('Public'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final service = ref.read(postServiceProvider);
                  await service.repost(widget.post.id);
                },
              ),
              ...groups.map((g) => ListTile(
                    leading: const Icon(LucideIcons.users),
                    title: Text(g.name),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final service = ref.read(postServiceProvider);
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
