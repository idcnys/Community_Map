import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// Handles all notification reads, writes, and group-broadcast logic.
class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

  // ─── SEND ────────────────────────────────────────────────────────
  /// Send a single notification to one user.
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
          'message': '$currentName posted in $groupName',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }
}
