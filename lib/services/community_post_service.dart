
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';
import '../models/notification_model.dart';

class CommunityPostService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── CREATE COMMUNITY POST ───────────────────────────────────────
  Future<String?> createPost({
    required String title,
    required String description,
    required String originType, // 'group' or 'public'
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify group members if posted in a group
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

  // ─── FEED: ALL COMMUNITY POSTS (client-side filtered) ─────────────
  /// Fetches all posts ordered by time. Filtering is done client-side
  /// to avoid Firestore composite index requirements.
  Stream<List<CommunityPostModel>> getAllPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// "All" feed: public posts + posts from user's groups
  Stream<List<CommunityPostModel>> getFeed(List<String> myGroupIds) {
    return getAllPosts().map((posts) => posts
        .where((p) => p.isPublic || myGroupIds.contains(p.groupId))
        .toList());
  }

  /// Feed filtered by a specific group
  Stream<List<CommunityPostModel>> getFeedByGroup(String groupId) {
    return getAllPosts().map((posts) => posts
        .where((p) => p.groupId == groupId)
        .toList());
  }

  /// All public posts
  Stream<List<CommunityPostModel>> getPublicFeed() {
    return getAllPosts().map((posts) => posts
        .where((p) => p.isPublic)
        .toList());
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

  // ─── INCREMENT VIEW COUNT ─────────────────────────────────────────
  Future<void> incrementView(String postId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  // ─── REPOST ───────────────────────────────────────────────────────
  Future<String?> repost(
    String postId, {
    String originType = 'public',
    String groupId = '',
    String groupName = 'Public',
  }) async {
    try {
      // Fetch original post
      final doc = await _firestore.collection('community_posts').doc(postId).get();
      if (!doc.exists) return 'Post not found';
      final original = doc.data()!;

      // Create repost as a new community post
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

      // Increment repost count on original
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

      // Notify post author
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

  /// Check if current user liked a post
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

      // Notify post author
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
        .snapshots()
        .map((snap) {
          final notifs = snap.docs
              .map((d) => AppNotificationModel.fromMap(d.id, d.data()))
              .toList();
          notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifs.take(50).toList();
        });
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
        if (memberId == currentUid) continue; // skip self
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

  // ─── GET USER'S GROUP IDS ────────────────────────────────────────
  Future<List<String>> getMyGroupIds() async {
    final created = await _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: currentUid)
        .get();
    final joined = await _firestore
        .collection('groups')
        .where('members', arrayContains: currentUid)
        .get();

    final ids = <String>{};
    for (final doc in created.docs) {
      ids.add(doc.id);
    }
    for (final doc in joined.docs) {
      ids.add(doc.id);
    }
    return ids.toList();
  }
}
