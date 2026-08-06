
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/report_post_model.dart';
import '../shared/services/user_group_service.dart';

class ReportPostService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _userGroupService = UserGroupService();

  String get currentUid => _auth.currentUser!.uid;
  String get currentName => _auth.currentUser?.displayName ?? 'User';

  // ─── CREATE REPORT POST ──────────────────────────────────────────
  Future<String?> createReport({
    required String contactNumber,
    required String reportType,
    required String description,
    required double latitude,
    required double longitude,
    List<String> sharedGroupIds = const [],
    String origin = 'public',
  }) async {
    try {
      await _firestore.collection('report_posts').add({
        'contactNumber': contactNumber,
        'reportType': reportType,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'authorId': currentUid,
        'authorName': currentName,
        'sharedGroupIds': sharedGroupIds,
        'origin': origin,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to submit report: $e';
    }
  }

  /// Rush/Urgent report - just location, no form
  Future<String?> createUrgentReport({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore.collection('report_posts').add({
        'contactNumber': '',
        'reportType': ReportTypes.urgentType,
        'description': 'Urgent emergency reported!',
        'latitude': latitude,
        'longitude': longitude,
        'authorId': currentUid,
        'authorName': currentName,
        'sharedGroupIds': <String>[],
        'origin': 'urgent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to submit urgent report: $e';
    }
  }

  // ─── GET ACTIVE REPORTS (within 48 hours) ────────────────────────
  Stream<List<ReportPostModel>> getActiveReports() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return _firestore
        .collection('report_posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── GET ARCHIVED REPORTS (older than 48 hours) ──────────────────
  Stream<List<ReportPostModel>> getArchivedReports() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return _firestore
        .collection('report_posts')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── GET LATEST REPORTS (for notification panel) ─────────────────
  Stream<List<ReportPostModel>> getLatestReports({int limit = 10}) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    return _firestore
        .collection('report_posts')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportPostModel.fromMap(d.id, d.data()))
            .toList());
  }

  // ─── DELETE REPORT ───────────────────────────────────────────────
  Future<String?> deleteReport(String reportId) async {
    try {
      await _firestore.collection('report_posts').doc(reportId).delete();
      return null;
    } catch (e) {
      return 'Failed to delete report: $e';
    }
  }

  // ─── GET MY REPORTS ──────────────────────────────────────────────
  Stream<List<ReportPostModel>> getMyReports() {
    return _firestore
        .collection('report_posts')
        .where('authorId', isEqualTo: currentUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReportPostModel.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // ─── UPDATE DESCRIPTION ──────────────────────────────────────────
  Future<String?> updateDescription(String reportId, String newDesc) async {
    try {
      await _firestore
          .collection('report_posts')
          .doc(reportId)
          .update({'description': newDesc});
      return null;
    } catch (e) {
      return 'Failed to update report: $e';
    }
  }

  // ─── GET USER'S GROUP IDS ────────────────────────────────────────
  Future<List<String>> getMyGroupIds({bool forceRefresh = false}) {
    return _userGroupService.getMyGroupIds(forceRefresh: forceRefresh);
  }

  // ─── LOCATION HELPERS ────────────────────────────────────────────
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
