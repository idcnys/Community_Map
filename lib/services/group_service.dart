
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

  // ─── SEARCH GROUPS (public only for discover) ────────────────────
  Stream<List<GroupModel>> searchGroups(String query) {
    if (query.isEmpty) {
      return _firestore
          .collection('groups')
          .where('isPrivate', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
    }
    // Firestore doesn't support full-text search; use prefix match on name
    // Filter private groups client-side since we can't combine != with range
    return _firestore
        .collection('groups')
        .orderBy('name')
        .startAt([query]).endAt(['$query\uf8ff'])
        .snapshots()
        .map((snap) =>
            snap.docs
                .map((d) => GroupModel.fromMap(d.id, d.data()))
                .where((g) => !g.isPrivate)
                .toList());
  }

  Stream<List<GroupModel>> getAllGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  // ─── USER'S GROUPS ───────────────────────────────────────────────
  Stream<List<GroupModel>> getMyCreatedGroups() {
    return _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: currentUid)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<GroupModel>> getMyJoinedGroups() {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUid)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<GroupModel>> getMyPendingRequests() {
    return _firestore
        .collection('groups')
        .where('pendingRequests', arrayContains: currentUid)
        .limit(50)
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
    bool isPrivate = false,
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
        'isPrivate': isPrivate,
        'invites': <String>[],
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

  // ─── REMOVE MEMBER (admin) ──────────────────────────────────────
  Future<String?> removeMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });
      return null;
    } catch (e) {
      return 'Failed to remove member: $e';
    }
  }

  // ─── LEAVE GROUP ─────────────────────────────────────────────────
  Future<String?> leaveGroup(String groupId) async {
    try {
      // Admin (creator) cannot leave their own group
      final doc = await _firestore.collection('groups').doc(groupId).get();
      final createdBy = doc.data()?['createdBy'] as String? ?? '';
      if (createdBy == currentUid) {
        return 'You cannot leave a group you created. Delete it instead.';
      }

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

  // ─── INVITES (private groups) ────────────────────────────────────

  /// Stream of groups where current user has a pending invite.
  Stream<List<GroupModel>> getMyInvites() {
    return _firestore
        .collection('groups')
        .where('invites', arrayContains: currentUid)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromMap(d.id, d.data())).toList());
  }

  /// Admin sends an invite to a user for a private group.
  Future<String?> sendInvite(String groupId, String userId) async {
    try {
      // Verify caller is admin
      final doc = await _firestore.collection('groups').doc(groupId).get();
      final data = doc.data();
      if (data == null) return 'Group not found.';
      if (data['createdBy'] != currentUid) return 'Only the admin can send invites.';
      if (!(data['isPrivate'] ?? false)) return 'This group is not private.';
      if ((data['members'] as List?)?.contains(userId) == true) {
        return 'User is already a member.';
      }
      if ((data['invites'] as List?)?.contains(userId) == true) {
        return 'User already has a pending invite.';
      }

      await _firestore.collection('groups').doc(groupId).update({
        'invites': FieldValue.arrayUnion([userId]),
      });
      return null;
    } catch (e) {
      return 'Failed to send invite: $e';
    }
  }

  /// User accepts an invite — added as member, invite removed.
  Future<String?> acceptInvite(String groupId) async {
    final canJoin = await canJoinGroup();
    if (!canJoin) {
      return 'You have reached the maximum of ${GroupLimits.maxTotal} total group activities.';
    }

    try {
      await _firestore.collection('groups').doc(groupId).update({
        'invites': FieldValue.arrayRemove([currentUid]),
        'members': FieldValue.arrayUnion([currentUid]),
        'memberCount': FieldValue.increment(1),
      });
      return null;
    } catch (e) {
      return 'Failed to accept invite: $e';
    }
  }

  /// User declines an invite — invite removed, no membership.
  Future<String?> declineInvite(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'invites': FieldValue.arrayRemove([currentUid]),
      });
      return null;
    } catch (e) {
      return 'Failed to decline invite: $e';
    }
  }

  /// Admin cancels a pending invite they sent.
  Future<String?> cancelInvite(String groupId, String userId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      final data = doc.data();
      if (data == null) return 'Group not found.';
      if (data['createdBy'] != currentUid) return 'Only the admin can cancel invites.';

      await _firestore.collection('groups').doc(groupId).update({
        'invites': FieldValue.arrayRemove([userId]),
      });
      return null;
    } catch (e) {
      return 'Failed to cancel invite: $e';
    }
  }

  /// Search users by name (case-insensitive substring match).
  /// Fetches recent users and filters client-side since Firestore
  /// doesn't support case-insensitive queries natively.
  Stream<List<Map<String, String>>> searchUsers(String query) {
    if (query.isEmpty) return Stream.value([]);
    final lowerQuery = query.toLowerCase();
    return _firestore
        .collection('users')
        .orderBy('fullName')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) {
              final data = d.data();
              return {
                'uid': d.id,
                'fullName': (data['fullName'] as String?) ?? 'Unknown',
                'imageUrl': (data['imageUrl'] as String?) ?? '',
              };
            })
            .where((u) => u['fullName']!.toLowerCase().contains(lowerQuery))
            .take(20)
            .toList());
  }
}
