import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';
import '../shared/services/user_group_service.dart';
import 'notification_service.dart';

/// Result of a paginated query: items + cursor for next page.
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDoc,
    required this.hasMore,
  });
}

/// Core post CRUD, feed queries, likes, comments, views, and reposts.
class PostService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _userGroupService = UserGroupService();
  final NotificationService notifications;

  PostService({NotificationService? notificationService})
      : notifications = notificationService ?? NotificationService();

  static const int pageSize = 20;

  /// Posts older than 2 days are excluded from the feed.
  /// Computed fresh per query so the cutoff never goes stale.
  Timestamp get _feedCutoff => Timestamp.fromDate(
    DateTime.now().subtract(const Duration(days: 2)),
  );

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  Future<String> _getMyImageUrl() async {
    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      return doc.data()?['imageUrl'] ?? '';
    } catch (_) {
      return '';
    }
  }

  // ─── CREATE POST ─────────────────────────────────────────────────
  Future<String?> createPost({
    required String title,
    required String description,
    required String originType,
    String groupId = '',
    String groupName = 'Public',
    String imageUrl = '',
  }) async {
    try {
      final authorImageUrl = await _getMyImageUrl();
      final docRef = await _firestore.collection('community_posts').add({
        'title': title,
        'description': description,
        'authorId': currentUid,
        'authorName': currentName,
        'authorImageUrl': authorImageUrl,
        'originType': originType,
        'groupId': groupId,
        'groupName': groupName,
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'repostCount': 0,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (originType == 'group' && groupId.isNotEmpty) {
        await notifications.notifyGroupMembers(
          groupId: groupId,
          postId: docRef.id,
          postTitle: title,
          type: 'new_post',
        );
      }

      return null;
    } catch (e) {
      return 'Failed to create post: $e';
    }
  }

  // ─── FEED QUERIES ────────────────────────────────────────────────

  Future<PaginatedResult<CommunityPostModel>> getPublicFeedPage({
    DocumentSnapshot? startAfter,
  }) async {
    var query = _firestore
        .collection('community_posts')
        .where('originType', isEqualTo: 'public')
        .where('createdAt', isGreaterThanOrEqualTo: _feedCutoff)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return _buildResult(snap);
  }

  Future<PaginatedResult<CommunityPostModel>> getGroupFeedPage(
    String groupId, {
    DocumentSnapshot? startAfter,
  }) async {
    var query = _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .where('createdAt', isGreaterThanOrEqualTo: _feedCutoff)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return _buildResult(snap);
  }

  Future<PaginatedResult<CommunityPostModel>> getAllFeedPage(
    List<String> myGroupIds, {
    DocumentSnapshot? publicCursor,
  }) async {
    // Fetch public posts (groupId='') + posts from user's groups only.
    // whereIn supports up to 30 values; sufficient for typical group counts.
    final allowedGroupIds = ['', ...myGroupIds];
    var query = _firestore
        .collection('community_posts')
        .where('groupId', whereIn: allowedGroupIds)
        .where('createdAt', isGreaterThanOrEqualTo: _feedCutoff)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (publicCursor != null) {
      query = query.startAfterDocument(publicCursor);
    }
    final snap = await query.get();
    return _buildResult(snap);
  }

  PaginatedResult<CommunityPostModel> _buildResult(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final items = snap.docs
        .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
        .toList();
    return PaginatedResult(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == pageSize,
    );
  }

  // ─── REALTIME STREAMS ────────────────────────────────────────────

  /// Streams posts created after [since], respecting the active filter.
  /// Used by PaginatedFeedNotifier to prepend new posts in real-time.
  Stream<List<CommunityPostModel>> streamNewPosts({
    required String filter,
    required List<String> myGroupIds,
    required DateTime since,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('community_posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (filter == 'public') {
      query = query.where('originType', isEqualTo: 'public');
    } else if (filter != 'all') {
      query = query.where('groupId', isEqualTo: filter);
    } else {
      final allowedGroupIds = ['', ...myGroupIds];
      query = query.where('groupId', whereIn: allowedGroupIds);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
        .toList());
  }


  Stream<List<CommunityPostModel>> streamPublicFeed({int limit = 20}) {
    return _firestore
        .collection('community_posts')
        .where('originType', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<CommunityPostModel>> streamGroupFeed(String groupId, {int limit = 20}) {
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── GET SINGLE POST ─────────────────────────────────────────────
  Stream<CommunityPostModel?> getPostById(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .snapshots()
        .map((snap) =>
            snap.exists ? CommunityPostModel.fromMap(snap.id, snap.data()!) : null);
  }

  // ─── VIEW COUNT ──────────────────────────────────────────────────
  Future<void> incrementViews(List<String> postIds) async {
    if (postIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in postIds) {
      batch.update(
        _firestore.collection('community_posts').doc(id),
        {'viewCount': FieldValue.increment(1)},
      );
    }
    await batch.commit();
  }

  // ─── REPOST ──────────────────────────────────────────────────────
  Future<String?> repost(
    String postId, {
    String originType = 'public',
    String groupId = '',
    String groupName = 'Public',
  }) async {
    try {
      final doc = await _firestore.collection('community_posts').doc(postId).get();
      if (!doc.exists) return 'Post not found';
      final original = doc.data()!;

      final authorImageUrl = await _getMyImageUrl();
      await _firestore.collection('community_posts').add({
        'title': original['title'] ?? '',
        'description': original['description'] ?? '',
        'authorId': currentUid,
        'authorName': currentName,
        'authorImageUrl': authorImageUrl,
        'originType': originType,
        'groupId': groupId,
        'groupName': groupName,
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'repostCount': 0,
        'originalPostId': postId,
        'originalAuthorName': original['authorName'] ?? 'Unknown',
        'imageUrl': original['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('community_posts').doc(postId).update({
        'repostCount': FieldValue.increment(1),
      });

      return null;
    } catch (e) {
      return 'Failed to repost: $e';
    }
  }

  // ─── DELETE POST ─────────────────────────────────────────────────
  Future<String?> deletePost(String postId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).delete();
      return null;
    } catch (e) {
      return 'Failed to delete post: $e';
    }
  }

  // ─── UPDATE POST ─────────────────────────────────────────────────
  Future<void> updatePost(String postId, {String? title, String? description, String? imageUrl, bool removeImage = false}) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (removeImage) {
      updates['imageUrl'] = '';
    } else if (imageUrl != null) {
      updates['imageUrl'] = imageUrl;
    }
    if (updates.isNotEmpty) {
      await _firestore.collection('community_posts').doc(postId).update(updates);
    }
  }

  // ─── MY POSTS ────────────────────────────────────────────────────
  Stream<List<CommunityPostModel>> getMyPosts() {
    return _firestore
        .collection('community_posts')
        .where('authorId', isEqualTo: currentUid)
        .limit(50)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
          .toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      return items;
    });
  }

  // ─── LIKES ───────────────────────────────────────────────────────
  Future<void> toggleLike(String postId, String postAuthorId) async {
    final likeRef = _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUid);

    final snap = await likeRef.get();

    if (snap.exists) {
      await likeRef.delete();
      await _firestore.collection('community_posts').doc(postId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({'createdAt': FieldValue.serverTimestamp()});
      await _firestore.collection('community_posts').doc(postId).update({
        'likeCount': FieldValue.increment(1),
      });

      if (postAuthorId != currentUid) {
        await notifications.send(
          targetUserId: postAuthorId,
          type: 'like',
          postId: postId,
          message: '$currentName liked your post',
        );
      }
    }
  }

  Future<bool> hasLiked(String postId) async {
    final snap = await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUid)
        .get();
    return snap.exists;
  }

  // ─── COMMENTS ────────────────────────────────────────────────────
  Stream<List<CommunityCommentModel>> getComments(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityCommentModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> addComment(
      String postId, String content, String postAuthorId) async {
    try {
      final authorImageUrl = await _getMyImageUrl();
      await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': content,
        'authorId': currentUid,
        'authorName': currentName,
        'authorImageUrl': authorImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('community_posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      if (postAuthorId != currentUid) {
        await notifications.send(
          targetUserId: postAuthorId,
          type: 'comment',
          postId: postId,
          message: '$currentName commented on your post',
        );
      }
      return null;
    } catch (e) {
      return 'Failed to add comment: $e';
    }
  }

  Future<String?> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
      await _firestore.collection('community_posts').doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
      return null;
    } catch (e) {
      return 'Failed to delete comment: $e';
    }
  }

  // ─── GROUP IDS (delegation) ──────────────────────────────────────
  Future<List<String>> getMyGroupIds({bool forceRefresh = false}) {
    return _userGroupService.getMyGroupIds(forceRefresh: forceRefresh);
  }
}
