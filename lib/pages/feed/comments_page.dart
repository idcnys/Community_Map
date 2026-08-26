
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/time_ago.dart';
import '../../providers/service_providers.dart';
import '../../providers/feed_providers.dart';
import '../../providers/guest_provider.dart';
import '../../models/community_post_model.dart';
import '../../services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentsPage extends ConsumerStatefulWidget {
  final String postId;
  final String postAuthorId;

  const CommentsPage({
    super.key,
    required this.postId,
    this.postAuthorId = '',
  });

  @override
  ConsumerState<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends ConsumerState<CommentsPage> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  String _resolvedAuthorId = '';
  bool _isLiked = false;
  bool _loadingLike = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    try {
      final service = ref.read(postServiceProvider);
      final liked = await service.hasLiked(widget.postId);
      if (mounted) setState(() => _isLiked = liked);
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('মন্তব্য')),
      body: Column(
        children: [
          // ─── ORIGINAL POST CONTEXT ─────────────────────────────────
          StreamBuilder<CommunityPostModel?>(
            stream: ref.read(postServiceProvider).getPostById(widget.postId),
            builder: (context, postSnap) {
              final post = postSnap.data;
              if (post == null) return const SizedBox.shrink();
              if (_resolvedAuthorId.isEmpty && post.authorId.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _resolvedAuthorId = post.authorId;
                });
              }

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outline),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: post.authorImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(post.authorImageUrl)
                              : null,
                          child: post.authorImageUrl.isEmpty
                              ? Text(
                                  post.authorName.isNotEmpty
                                      ? post.authorName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 13),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                formatShortDate(post.createdAt ?? DateTime.now()),
                                style: TextStyle(fontFamily: 'EkusheInter', fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (!post.isPublic)
                          Chip(
                            label: Text(post.groupName, style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      post.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'EkusheInter', fontSize: 13, color: theme.colorScheme.onSurface),
                    ),
                    if (post.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    // ─── ACTION BUTTONS ROW ────────────────────────
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 4),
                    Builder(builder: (ctx) {
                      final isGuest = ref.read(isGuestProvider);
                      final isOwn = _isOwnPost(post);
                      return Row(
                        children: [
                          // Like button
                          InkWell(
                            onTap: (isGuest || _loadingLike) ? null : () => _toggleLike(post),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLiked ? Icons.thumb_up : LucideIcons.thumbsUp,
                                    size: 16,
                                    color: _isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likeCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Comment count (non-interactive, already on this page)
                          _metricChip(theme, LucideIcons.messageCircle, post.commentCount),
                          const SizedBox(width: 8),
                          // Repost button
                          if (!isOwn && !isGuest && !post.isRepost)
                            InkWell(
                              onTap: () => _repostFromComments(post),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.repeat, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.repostCount}',
                                      style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _metricChip(theme, LucideIcons.repeat, post.repostCount),
                          const SizedBox(width: 8),
                          // View count
                          _metricChip(theme, LucideIcons.eye, post.viewCount),
                          const Spacer(),
                          // Report button
                          if (!isOwn && !isGuest)
                            InkWell(
                              onTap: () => _showReportDialog(context, post),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.flag, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text('রিপোর্ট', style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // ─── COMMENTS LIST ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<CommunityCommentModel>>(
              stream: ref.read(postServiceProvider).getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'এখনো কোনো মন্তব্য নেই।\nপ্রথম মন্তব্য করুন!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'EkusheInter', color: theme.colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (ctx, i) {
                    final comment = comments[i];
                    final isOwn = comment.authorId == ref.read(postServiceProvider).currentUid;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: comment.authorImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(comment.authorImageUrl)
                              : null,
                          child: comment.authorImageUrl.isEmpty
                              ? Text(
                                  comment.authorName.isNotEmpty
                                      ? comment.authorName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(comment.authorName,
                            style:
                                const TextStyle(fontFamily: 'EkusheInter', fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(comment.content),
                            const SizedBox(height: 4),
                            Text(
                              formatShortDate(comment.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: isOwn
                            ? IconButton(
                                icon: Icon(LucideIcons.trash2,
                                    size: 20, color: theme.colorScheme.error),
                                onPressed: () => _deleteComment(comment.id),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'একটি মন্তব্য লিখুন...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.send, size: 20),
                      onPressed: _sending ? null : _sendComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    final authorId = widget.postAuthorId.isNotEmpty ? widget.postAuthorId : _resolvedAuthorId;
    final error = await ref.read(postServiceProvider).addComment(
        widget.postId, content, authorId);
    setState(() => _sending = false);

    if (error == null) {
      _commentCtrl.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final error = await ref.read(postServiceProvider).deleteComment(widget.postId, commentId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    setState(() {
      _isLiked = !_isLiked;
      _loadingLike = true;
    });
    final service = ref.read(postServiceProvider);
    await service.toggleLike(post.id, post.authorId);
    if (mounted) setState(() => _loadingLike = false);
  }

  Future<void> _repostFromComments(CommunityPostModel post) async {
    final service = ref.read(postServiceProvider);
    final error = await service.repost(
      post.id,
      originType: post.isPublic ? 'public' : 'group',
      groupId: post.groupId,
      groupName: post.groupName,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সফলভাবে রিপোস্ট হয়েছে'), duration: Duration(seconds: 2)),
      );
    }
  }

  bool _isOwnPost(CommunityPostModel post) {
    return post.authorId == FirebaseAuth.instance.currentUser?.uid;
  }

  Widget _metricChip(ThemeData theme, IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(fontFamily: 'EkusheInter', fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showReportDialog(BuildContext context, CommunityPostModel post) {
    final isGuest = ref.read(isGuestProvider);
    if (isGuest) return;

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
            Expanded(child: Text('পোস্ট রিপোর্ট করুন', style: Theme.of(ctx).textTheme.titleMedium)),
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
              'আপনি কেন এই পোস্টটি রিপোর্ট করছেন?',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...PostService.reportCauses.map((cause) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 4,
              title: Text(cause, style: const TextStyle(fontFamily: 'EkusheInter', fontSize: 13)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final error = await service.reportPost(post.id, cause);
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                } else {
                  ref.read(reportedPostsProvider.notifier).add(post.id);
                  ref.read(paginatedFeedProvider.notifier).removePost(post.id);
                  // Navigate back since the post is now hidden
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('পোস্ট রিপোর্ট হয়েছে। এটি আপনার ফিড থেকে লুকানো হবে।'),
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
}
