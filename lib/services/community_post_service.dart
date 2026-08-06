
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';
import '../models/notification_model.dart';
import '../shared/services/user_group_service.dart';

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

class CommunityPostService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _userGroupService = UserGroupService();

  static const int pageSize = 20;

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── CREATE COMMUNITY POST ───────────────────────────────────────
  Future<String?> createPost({
    required String title,
    required String description,
    required String originType,
    String groupId = '',
    String groupName = 'Public',
  }) async {
    try {
      final docRef = await _firestore.collection('community_posts').add({
        'title': title,
        'description': description,
        'authorId': currentUid,
        'authorName': currentName,
        'originType': originType,
        'groupId': groupId,
        'groupName': groupName,
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'repostCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (originType == 'group' && groupId.isNotEmpty) {
        await _notifyGroupMembers(
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

  // ─── SERVER-SIDE FEED QUERIES (no client-side filtering) ─────────

  /// Public posts only — uses composite index (originType, createdAt).
  Query<Map<String, dynamic>> _publicQuery() {
    return _firestore
        .collection('community_posts')
        .where('originType', isEqualTo: 'public')
        .orderBy('createdAt', descending: true);
  }

  /// Posts from a specific group — uses composite index (groupId, createdAt).
  Query<Map<String, dynamic>> _groupQuery(String groupId) {
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true);
  }



  // ─── PAGINATED FEED (cursor-based) ───────────────────────────────

  /// Load first page of public feed.
  Future<PaginatedResult<CommunityPostModel>> getPublicFeedPage({
    DocumentSnapshot? startAfter,
  }) async {
    var query = _publicQuery().limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return _buildResult(snap);
  }

  /// Load first page of a specific group's feed.
  Future<PaginatedResult<CommunityPostModel>> getGroupFeedPage(
    String groupId, {
    DocumentSnapshot? startAfter,
  }) async {
    var query = _groupQuery(groupId).limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return _buildResult(snap);
  }

  /// Load "all" feed page: merges public + group posts.
  /// Fetches from both sources and merges by createdAt descending.
  Future<PaginatedResult<CommunityPostModel>> getAllFeedPage(
    List<String> myGroupIds, {
    DocumentSnapshot? publicCursor,
    DocumentSnapshot? groupCursor,
  }) async {
    // Fetch public posts
    var pubQuery = _publicQuery().limit(pageSize);
    if (publicCursor != null) {
      pubQuery = pubQuery.startAfterDocument(publicCursor);
    }

    // Fetch group posts (whereIn limited to 30)
    final feedGroupIds = myGroupIds.take(29).toList();
    Query<Map<String, dynamic>>? grpQuery;
    if (feedGroupIds.isNotEmpty) {
      grpQuery = _firestore
          .collection('community_posts')
          .where('groupId', whereIn: feedGroupIds)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (groupCursor != null) {
        grpQuery = grpQuery.startAfterDocument(groupCursor);
      }
    }

    // Execute queries in parallel
    final results = await Future.wait([
      pubQuery.get(),
      if (grpQuery != null) grpQuery.get(),
    ]);

    final pubSnap = results[0];
    final grpSnap = results.length > 1 ? results[1] : null;

    // Merge and sort by createdAt descending
    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
      ...pubSnap.docs,
      if (grpSnap != null) ...grpSnap.docs,
    ];
    allDocs.sort((a, b) {
      final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    // Take only pageSize items
    final trimmed = allDocs.take(pageSize).toList();
    final items = trimmed
        .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
        .toList();

    return PaginatedResult(
      items: items,
      lastDoc: trimmed.isNotEmpty ? trimmed.last : null,
      hasMore: pubSnap.docs.length == pageSize ||
          (grpSnap != null && grpSnap.docs.length == pageSize),
    );
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

  // ─── REALTIME STREAM (for live updates on current page) ──────────

  Stream<List<CommunityPostModel>> streamPublicFeed({int limit = 20}) {
    return _publicQuery().limit(limit).snapshots().map((snap) =>
        snap.docs.map((d) => CommunityPostModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<CommunityPostModel>> streamGroupFeed(String groupId, {int limit = 20}) {
    return _groupQuery(groupId).limit(limit).snapshots().map((snap) =>
        snap.docs.map((d) => CommunityPostModel.fromMap(d.id, d.data())).toList());
  }

  // ─── GET SINGLE POST ──────────────────────────────────────────────
  Stream<CommunityPostModel?> getPostById(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .snapshots()
        .map((snap) =>
            snap.exists ? CommunityPostModel.fromMap(snap.id, snap.data()!) : null);
  }

  // ─── VIEW COUNT (batched via ViewCountBatcher) ────────────────────
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

  // ─── REPOST ───────────────────────────────────────────────────────
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

      await _firestore.collection('community_posts').add({
        'title': original['title'] ?? '',
        'description': original['description'] ?? '',
        'authorId': currentUid,
        'authorName': currentName,
        'originType': originType,
        'groupId': groupId,
        'groupName': groupName,
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'repostCount': 0,
        'originalPostId': postId,
        'originalAuthorName': original['authorName'] ?? 'Unknown',
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
        await _sendNotification(
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
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityCommentModel.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String?> addComment(
      String postId, String content, String postAuthorId) async {
    try {
      await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': content,
        'authorId': currentUid,
        'authorName': currentName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('community_posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      if (postAuthorId != currentUid) {
        await _sendNotification(
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

  // ─── NOTIFICATIONS ───────────────────────────────────────────────
  Stream<List<AppNotificationModel>> getMyNotifications() {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotificationModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markNotificationRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'read': true,
    });
  }

  Future<void> markAllNotificationsRead() async {
    final snap = await _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  Future<void> _sendNotification({
    required String targetUserId,
    required String type,
    required String postId,
    String postTitle = '',
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'targetUserId': targetUserId,
      'actorId': currentUid,
      'actorName': currentName,
      'postId': postId,
      'postTitle': postTitle,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _notifyGroupMembers({
    required String groupId,
    required String postId,
    required String postTitle,
    required String type,
  }) async {
    try {
      final groupSnap =
          await _firestore.collection('groups').doc(groupId).get();
      final members =
          List<String>.from(groupSnap.data()?['members'] ?? []);

      final batch = _firestore.batch();
      for (final memberId in members) {
        if (memberId == currentUid) continue;
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'type': type,
          'targetUserId': memberId,
          'actorId': currentUid,
          'actorName': currentName,
          'postId': postId,
          'postTitle': postTitle,
          'message': '$currentName posted in ${groupSnap.data()?['name'] ?? 'group'}',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<List<String>> getMyGroupIds({bool forceRefresh = false}) {
    return _userGroupService.getMyGroupIds(forceRefresh: forceRefresh);
  }
}
