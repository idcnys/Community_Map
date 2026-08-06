import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared service for user-group queries. Eliminates duplicate
/// getMyGroupIds() that existed in both CommunityPostService and ReportPostService.
class UserGroupService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  /// Returns all group IDs the user created or joined.
  /// Caches result for 30s to avoid redundant queries.
  List<String>? _cachedGroupIds;
  DateTime? _cacheTime;

  Future<List<String>> getMyGroupIds({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedGroupIds != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inSeconds < 30) {
      return _cachedGroupIds!;
    }

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

    _cachedGroupIds = ids.toList();
    _cacheTime = DateTime.now();
    return _cachedGroupIds!;
  }

  void invalidateCache() {
    _cachedGroupIds = null;
    _cacheTime = null;
  }
}
