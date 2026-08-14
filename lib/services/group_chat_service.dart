import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class GroupChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── GROUP CHAT ─────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limitToLast(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<String?> sendMessage(String groupId, String text) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': currentUid,
        'senderName': currentName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to send: $e';
    }
  }

  // ─── LIVE LOCATION SHARING ──────────────────────────────────────
  Future<String?> shareLocationToGroup(String groupId, double lat, double lng) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('member_locations')
          .doc(currentUid)
          .set({
        'uid': currentUid,
        'name': currentName,
        'latitude': lat,
        'longitude': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      return 'Failed to share location: $e';
    }
  }

  Stream<List<Map<String, dynamic>>> getGroupMemberLocations(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('member_locations')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<Map<String, dynamic>?> getMemberLocation(String groupId, String uid) async {
    try {
      final doc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('member_locations')
          .doc(uid)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  // ─── LAST ACTIVE ────────────────────────────────────────────────
  Future<void> updateLastActive() async {
    try {
      await _firestore.collection('users').doc(currentUid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) { debugPrint('[] error: $e'); }
  }

  Future<DateTime?> getLastActive(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final ts = doc.data()?['lastActive'] as Timestamp?;
      return ts?.toDate();
    } catch (_) {
      return null;
    }
  }

  // ─── READ RECEIPTS (for unread badge) ───────────────────────────
  Future<void> markGroupAsRead(String groupId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('read_receipts')
          .doc(currentUid)
          .set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) { debugPrint('[] error: $e'); }
  }

  Stream<int> getUnreadCount(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('read_receipts')
        .doc(currentUid)
        .snapshots()
        .asyncMap((receiptSnap) async {
      final lastRead = (receiptSnap.data()?['lastReadAt'] as Timestamp?)?.toDate();
      if (lastRead == null) {
        // Never read — count messages (capped to avoid unbounded reads)
        final msgSnap = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('messages')
            .limit(200)
            .get();
        return msgSnap.docs.where((d) => d.data()['senderId'] != currentUid).length;
      }
      final msgSnap = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastRead))
          .limit(200)
          .get();
      // Exclude own messages from unread count
      return msgSnap.docs.where((d) => d.data()['senderId'] != currentUid).length;
    });
  }

}
