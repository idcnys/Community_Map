
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  Stream<UserProfile?> getProfile() {
    return _firestore
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .map((snap) =>
            snap.exists ? UserProfile.fromMap(snap.id, snap.data()!) : null);
  }

  Future<String?> updateProfile({
    required String fullName,
    String bio = '',
    String phone = '',
    String location = '',
    String dateOfBirth = '',
    String? imageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(currentUid).update({
        'fullName': fullName,
        'bio': bio,
        'phone': phone,
        'location': location,
        'dateOfBirth': dateOfBirth,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      // Also update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(fullName);
      return null;
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
}
