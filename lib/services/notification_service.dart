import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'push_notification_service.dart';

/// Handles all notification reads, writes, and group-broadcast logic.
/// Also triggers push notifications via Supabase Edge Function.
class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _push = PushNotificationService();

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── READ ────────────────────────────────────────────────────────
  Stream<List<AppNotificationModel>> getMyNotifications() {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .limit(50)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => AppNotificationModel.fromMap(d.id, d.data()))
          .toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      return items;
    });
  }

  Stream<int> getUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .where('read', isEqualTo: false)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── MARK READ ───────────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({
      'read': true,
    });
  }

  Future<void> markAllRead() async {
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

  // ─── CLEAR ALL ──────────────────────────────────────────────────
  Future<void> clearAll() async {
    final snap = await _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: currentUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── SEND ────────────────────────────────────────────────────────
  /// Send a single notification to one user (Firestore + push).
  Future<void> send({
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

    // Fire push notification (non-blocking, won't fail the main flow)
    _push.pushToUser(
      targetUserId: targetUserId,
      title: _pushTitle(type),
      body: message,
      data: {'type': type, 'postId': postId},
    );
  }

  /// Notify all members of a group (except the actor).
  Future<void> notifyGroupMembers({
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
      final groupName = groupSnap.data()?['name'] ?? 'group';

      final batch = _firestore.batch();
      final targetMembers = <String>[];

      for (final memberId in members) {
        if (memberId == currentUid) continue;
        targetMembers.add(memberId);
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'type': type,
          'targetUserId': memberId,
          'actorId': currentUid,
          'actorName': currentName,
          'postId': postId,
          'postTitle': postTitle,
          'message': '$currentName posted in $groupName',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Fire push to all group members (non-blocking)
      if (targetMembers.isNotEmpty) {
        _push.pushToUsers(
          targetUserIds: targetMembers,
          title: _pushTitle(type),
          body: '$currentName posted in $groupName',
          data: {'type': type, 'postId': postId, 'groupId': groupId},
        );
      }
    } catch (e) { debugPrint('[] error: $e'); }
  }

  /// Notify ALL registered users (except the actor) — used for new reports.
  Future<void> notifyAllUsers({
    required String reportId,
    required String type,
    required String message,
  }) async {
    try {
      final usersSnap = await _firestore.collection('users').limit(200).get();

      final batch = _firestore.batch();
      final targetUsers = <String>[];

      for (final doc in usersSnap.docs) {
        if (doc.id == currentUid) continue;
        targetUsers.add(doc.id);
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'type': type,
          'targetUserId': doc.id,
          'actorId': currentUid,
          'actorName': currentName,
          'postId': reportId,
          'postTitle': '',
          'message': message,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Fire push to all users (non-blocking)
      if (targetUsers.isNotEmpty) {
        _push.pushToUsers(
          targetUserIds: targetUsers,
          title: _pushTitle(type),
          body: message,
          data: {'type': type, 'postId': reportId},
        );
      }
    } catch (e) { debugPrint('[] error: $e'); }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _pushTitle(String type) {
    switch (type) {
      case 'like':
        return 'New Like';
      case 'comment':
        return 'New Comment';
      case 'new_post':
        return 'New Post';
      case 'new_report':
        return '🚨 New Report';
      case 'join_request':
        return 'Join Request';
      case 'member_approved':
        return 'Request Approved';
      case 'repost':
        return '🔁 Reposted';
      default:
        return 'Notification';
    }
  }
}
