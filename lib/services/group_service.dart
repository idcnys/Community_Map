
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';

class GroupLimits {
  static const int maxCreated = 3;
  static const int maxJoined = 5;
  static const int maxTotal = 8;
}

class GroupService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── SEARCH GROUPS ───────────────────────────────────────────────
  Stream<List<GroupModel>> searchGroups(String query) {
    if (query.isEmpty) {
      return _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
    }
    // Firestore doesn't support full-text search; use prefix match on name
    return _firestore
        .collection('groups')
        .orderBy('name')
        .startAt([query]).endAt(['$query\uf8ff'])
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<GroupModel>> getAllGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  // ─── USER'S GROUPS ───────────────────────────────────────────────
  Stream<List<GroupModel>> getMyCreatedGroups() {
    return _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: currentUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<GroupModel>> getMyJoinedGroups() {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<GroupModel>> getMyPendingRequests() {
    return _firestore
        .collection('groups')
        .where('pendingRequests', arrayContains: currentUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  // ─── COUNTS ──────────────────────────────────────────────────────
  Future<int> getCreatedCount() async {
    final snap = await _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: currentUid)
        .get();
    return snap.docs.length;
  }

  Future<int> getJoinedCount() async {
    final snap = await _firestore
        .collection('groups')
        .where('members', arrayContains: currentUid)
        .get();
    return snap.docs.length;
  }

  Future<int> getTotalCount() async {
    final created = await getCreatedCount();
    final joined = await getJoinedCount();
    return created + joined;
  }

  Future<bool> canCreateGroup() async {
    final count = await getCreatedCount();
    return count < GroupLimits.maxCreated;
  }

  Future<bool> canJoinGroup() async {
    final total = await getTotalCount();
    return total < GroupLimits.maxTotal;
  }

  // ─── CREATE GROUP ────────────────────────────────────────────────
  Future<String?> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final canCreate = await canCreateGroup();
      if (!canCreate) {
        return 'You can create a maximum of ${GroupLimits.maxCreated} groups.';
      }

      final canJoin = await canJoinGroup();
      if (!canJoin) {
        return 'You have reached the maximum of ${GroupLimits.maxTotal} total group activities.';
      }
    } catch (_) {
      // Limit check failed — proceed with creation attempt anyway
    }

    try {
      await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'createdBy': currentUid,
        'createdByName': currentName,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'members': [currentUid],
        'pendingRequests': <String>[],
      });
      return null; // success
    } catch (e) {
      return 'Failed to create group: $e';
    }
  }

  // ─── UPDATE GROUP ────────────────────────────────────────────────
  Future<String?> updateGroup({
    required String groupId,
    required String name,
    required String description,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'name': name,
        'description': description,
      });
      return null;
    } catch (e) {
      return 'Failed to update group: $e';
    }
  }

  // ─── DELETE GROUP ────────────────────────────────────────────────
  Future<String?> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      return null;
    } catch (e) {
      return 'Failed to delete group: $e';
    }
  }

  // ─── JOIN REQUEST ────────────────────────────────────────────────
  Future<String?> sendJoinRequest(String groupId) async {
    final canJoin = await canJoinGroup();
    if (!canJoin) {
      return 'You have reached the maximum of ${GroupLimits.maxTotal} total group activities.';
    }

    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequests': FieldValue.arrayUnion([currentUid]),
      });
      return null;
    } catch (e) {
      return 'Failed to send request: $e';
    }
  }

  Future<String?> cancelJoinRequest(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequests': FieldValue.arrayRemove([currentUid]),
      });
      return null;
    } catch (e) {
      return 'Failed to cancel request: $e';
    }
  }

  // ─── APPROVE / REJECT (for group owners) ─────────────────────────
  Future<String?> approveMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
      return null;
    } catch (e) {
      return 'Failed to approve: $e';
    }
  }

  Future<String?> rejectMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
      });
      return null;
    } catch (e) {
      return 'Failed to reject: $e';
    }
  }

  // ─── LEAVE GROUP ─────────────────────────────────────────────────
  Future<String?> leaveGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([currentUid]),
        'memberCount': FieldValue.increment(-1),
      });
      return null;
    } catch (e) {
      return 'Failed to leave group: $e';
    }
  }

  // ─── GET SINGLE GROUP ────────────────────────────────────────────
  Stream<GroupModel?> getGroupById(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((snap) => snap.exists ? GroupModel.fromMap(snap.id, snap.data()!) : null);
  }
}
