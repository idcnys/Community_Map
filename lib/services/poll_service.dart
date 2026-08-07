import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles poll creation, voting, and vote queries.
class PollService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── CREATE POLL POST ────────────────────────────────────────────
  Future<String?> createPollPost({
    required String title,
    required String description,
    required List<String> pollOptions,
    required String pollType, // 'single' or 'multi'
    required String originType,
    String groupId = '',
    String groupName = 'Public',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Not authenticated';

      final pollVotes = <String, List<String>>{};
      for (int i = 0; i < pollOptions.length; i++) {
        pollVotes['$i'] = [];
      }

      await _firestore.collection('community_posts').add({
        'title': title,
        'description': description,
        'authorId': user.uid,
        'authorName': user.displayName ?? user.email ?? 'Unknown',
        'originType': originType,
        'groupId': groupId,
        'groupName': groupName,
        'likeCount': 0,
        'commentCount': 0,
        'viewCount': 0,
        'repostCount': 0,
        'originalPostId': '',
        'originalAuthorName': '',
        'isPoll': true,
        'pollOptions': pollOptions,
        'pollType': pollType,
        'pollVotes': pollVotes,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to create poll: $e';
    }
  }

  // ─── VOTE ────────────────────────────────────────────────────────
  Future<void> vote(String postId, List<String> optionIndexes) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    final snap = await postRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final pollVotes = Map<String, List<String>>.from(
      (data['pollVotes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v ?? [])),
      ) ?? {},
    );
    final pollType = data['pollType'] ?? 'single';

    // Remove user's previous votes
    for (final key in pollVotes.keys) {
      pollVotes[key]!.remove(currentUid);
    }

    // Add new votes
    if (pollType == 'single') {
      final idx = optionIndexes.first;
      pollVotes.putIfAbsent(idx, () => []);
      pollVotes[idx]!.add(currentUid);
    } else {
      for (final idx in optionIndexes) {
        pollVotes.putIfAbsent(idx, () => []);
        pollVotes[idx]!.add(currentUid);
      }
    }

    await postRef.update({'pollVotes': pollVotes});
  }

  // ─── GET MY VOTES ────────────────────────────────────────────────
  /// Check which options the current user voted for.
  Future<List<String>> getMyVotes(String postId) async {
    final snap = await _firestore.collection('community_posts').doc(postId).get();
    if (!snap.exists) return [];
    final data = snap.data()!;
    final pollVotes = data['pollVotes'] as Map<String, dynamic>? ?? {};
    final myVotes = <String>[];
    for (final entry in pollVotes.entries) {
      final voters = List<String>.from(entry.value ?? []);
      if (voters.contains(currentUid)) myVotes.add(entry.key);
    }
    return myVotes;
  }
}
